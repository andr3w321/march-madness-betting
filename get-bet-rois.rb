#!/usr/bin/ruby

require 'mechanize'
require 'nokogiri'
require 'json'

ROUND = 3

class Team
  attr_accessor :team_name
  attr_accessor :money_line
  attr_accessor :line_win_per
  attr_accessor :silver_win_per
  attr_accessor :roi
  attr_accessor :quarter_kelly

  def initialize(team_name)
    @team_name = team_name
    @money_line = 0
    @line_win_per = 0
    @silver_win_per = 0
    @roi = 0
    @quarter_kelly = 0
  end
end

def replace_team_name_alias(name)
  if(name == "Cal Irvine")
    return "UC Irvine"
  end
  if(name == "SMU")
    return "Southern Methodist"
  end
  if(name == "Indiana U")
    return "Indiana"
  end
  if(name == "Utah U")
    return "Utah"
  end
  if(name == "Va Commonwealth")
    return "Virginia Commonwealth"
  end
  if(name == "E. Washington")
    return "Eastern Washington"
  end
  if(name == "Mississippi")
    return "Ole Miss"
  end
  #if(name == "Northwestern State")
  #if(name == "Tenn Martin")
  if(name == "N. Dakota State")
    return "North Dakota State"
  end
  if(name == "NC State")
    return "North Carolina State"
  end
  if(name == "Albany NY")
    return "Albany"
  end
  return name
end

def get_pinnacle
  agent = Mechanize.new
  url = 'https://www.pinnaclesports.com/League/Basketball/NCAA/1/Lines.aspx'
  puts url
  agent.get(url)
  doc = Nokogiri::HTML(agent.page.body)
  rows = doc.css('tr')
  teams = []
  rows.each do |row|
    if row.children.length > 7
      if !row.children[6].text.empty?
        #puts row.children[3].text.strip + "," + row.children[6].text.gsub(/[[:space:]]/, ' ').split.join
        t = Team.new(replace_team_name_alias(row.children[3].text.strip))
        t.money_line = row.children[6].text.gsub(/[[:space:]]/, ' ').split.join.to_f
        t.line_win_per = 1/t.money_line
        teams.push(t)
      end
    end
  end
  return teams
end

# find latest tsv filename
def get_latest_silver_bracket_filename
  agent = Mechanize.new
  agent.get('https://api.github.com/repos/fivethirtyeight/data/contents/march-madness-predictions-2015/mens')
  results = JSON.parse(agent.page.body)
  # TODO do a more clean parse of latest filename
  bracket_filename = results[results.length-1]["name"]
  return bracket_filename
end

def get_silver(teams)
  agent = Mechanize.new
  latest_bracket_filename = get_latest_silver_bracket_filename
  url = "https://raw.githubusercontent.com/fivethirtyeight/data/master/march-madness-predictions-2015/mens/" + latest_bracket_filename
  puts url
  agent.get(url)
  doc = Nokogiri::HTML(agent.page.body)
  rows = doc.text.split("\n")
  for i in 1..rows.length-1
    cols = rows[i].split("\t")
    # see if have current team name
    # once found save the roi and silver win percent
    for i in 0..teams.length-1
      if(cols[1] == teams[i].team_name)
        teams[i].silver_win_per = cols[ROUND + 4].to_f
        teams[i].roi = (teams[i].silver_win_per * (teams[i].money_line - 1) - (1 - teams[i].silver_win_per)).to_f
        if(teams[i].roi > 0)
          b = teams[i].money_line - 1
          p = teams[i].silver_win_per
          q = 1 - p
          teams[i].quarter_kelly = (b*p-q)/b/4
        end
        break
      end
    end
  end

  teams = teams.sort_by(&:roi).reverse
  return teams
end

def print_teams(teams)
  printf "%-25s%-25s%-25s%-25s%-25s%-25s\n", "team_name", "money_line", "line_win_per", "silver_win_per", "roi", "1/4 kelly"
  for i in 0..teams.length-1
    printf "%-25s%-25s%-25s%-25s%-25s%-25s\n", teams[i].team_name, teams[i].money_line.to_s, teams[i].line_win_per.to_s, teams[i].silver_win_per.to_s, teams[i].roi.to_s, teams[i].quarter_kelly.to_s
  end
end


puts "scraping from urls:"
teams = get_pinnacle
teams = get_silver(teams)
print "\n"
print_teams(teams)

