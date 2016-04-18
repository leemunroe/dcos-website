#!/usr/bin/env ruby

# change to repo root
Dir.chdir(File.join(File.dirname(__FILE__), ".."))

diffs = `git diff --cached`.split('diff --git').select { |log| log =~ /Subproject/ }

locations = {}
diffs.each do |diff|
  /a\/(?<loc>.+?)\sb.*index\s(?<shas>\S+)/m.match diff do |matches|
    locations[matches[:loc]] = matches[:shas]
  end
end

puts "Bump #{locations.keys.join(", ")}"
puts # Second line of git commit message should always be empty

locations.each do |location, shas|
  Dir.chdir(location) do
    remote = `git remote -v`.match(/github.com[\/:]([^\s]+?).git/)
    repo = remote && remote[1]

    puts "Bump #{repo}"

    commit_messages_by_author = Hash.new([])
    `git log #{shas} --pretty=format:'%h %an: %s'`.split("\n").each do |commit|
      _sha, rest_of_commit = commit.split(" ", 2)
      author, message = rest_of_commit.split(":", 2)

      next if message.include?('Merge pull request')
      next if message.include?("Merge branch 'master'")

      commit_messages_by_author[author] += [message]
    end

    commit_messages_by_author.each do |author, messages|
      puts "  #{author}:"
      messages.each { |message| puts "    #{message}" }
    end
  end
end
