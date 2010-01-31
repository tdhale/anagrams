require 'bag'

# First snarf the dictionary and do as much pre-processing as we can

def Read(fn)
  the_list = []
  begin
    File.open("dict.cache", "r") do |fp|
      printf "Snarfing dict.cache ..."
      $stdout.flush
      the_list = Marshal.load(fp.read)
      puts "Loaded dictionary from dict.cache"
    end

  rescue Errno::ENOENT
    the_hash = {}
    File.open(fn, "r") do |aFile|
      printf "Snarfing #{fn} ..."
      $stdout.flush
      has_a_vowel_re = /[aeiouy]/
      long_enough_re = /^(..|i|a)/
      has_a_non_letter_re = /[^a-z]/
      aFile.each_line do |aLine|
        aLine.chomp!()
        aLine.downcase!()
        next if has_a_non_letter_re.match(aLine)
        next if !has_a_vowel_re.match(aLine)
        next if !long_enough_re.match(aLine)

        b = Bag.new(aLine)
        if (the_hash.has_key?(b))
          the_hash[b] = the_hash[b] | [aLine]     # avoid duplicates
        else
          the_hash[b] = [aLine]
        end
      end
    end
    File.open("dict.cache", "w") do |aCache|
      the_hash.each {
        | bag, words |
        the_list.push([bag, words])
      }
      # Sort biggest first; that makes things faster for some reason
      puts the_list[0]
      the_list.sort! {|a, b| b[0] <=> a[0]}
      puts the_list[0]

      Marshal.dump(the_list, aCache)
      puts "Wrote dict.cache"
    end
  end
  puts " (#{the_list.length} bags; #{the_list.inject(0) {|memo, obj| memo + obj[1].length()}} words) done"
  the_list
end
