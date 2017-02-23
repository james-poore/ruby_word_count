require 'optparse'
require 'pp'

APP_NAME = "wc.rb"
APP_VERSION = "v1.0"
APP_AUTHOR = "James L Poore Jr."

DEBUG = false

options = {}
$text_from_stdin = false
$names_from_stdin = false
$error_message = ""

optparse = OptionParser.new do |opts|
  opts.banner = "Usage:  wc.rb [options] [file1 file2 ...]\n" +
                "\twc.rb [options] --files0-from=F\n\n" +
                "Options:\n"

  # Read in the options
  options[:bytes] = false
  opts.on('-c', '--bytes', 'Print the number of bytes in the file/s') do
    options[:bytes] = true
  end

  options[:chars] = false
  opts.on('-m', '--chars', 'Print the number of characters in the file/s') do
    options[:chars] = true
  end

  options[:lines] = false
  opts.on('-l', '--lines', 'Print the number of lines in the file/s') do
    options[:lines] = true
  end

  options[:words] = false
  opts.on('-w', '--words', 'Print the number of words in the file/s') do
    options[:words] = true
  end

  options[:max_line_length] = false
  opts.on('-L', '--max-line-length', 'Print the length of the longest line in the file/s') do
    options[:max_line_length] = true
  end

  options[:input_file] = nil
  opts.on('--files0-from=file_name', "Read input from the files specified by\n" +
          "\t\t\t\t\tNUL-terminated names in file file_name;\n" +
          "\t\t\t\t\tIf file_name is - then read names from standard input") do |file_name|
    if file_name == '-'
      $names_from_stdin = true
      options[:input_file] = $stdin
    else
      begin
        options[:input_file] = File.new(file_name, "r")
      rescue Exception => ex
        puts "An error of type #{ex.class} happened, message is #{ex.message}"
      end
    end
  end

  # This displays the version and exits
  opts.on('-v', '--version', 'Output the version of this app') do
    puts "#{APP_NAME} #{APP_VERSION}"
    puts "Copyright (c) 2015 #{APP_AUTHOR}"
    puts ""
    puts "Written by #{APP_AUTHOR}"
    exit
  end

  # This displays the help screen and exits.
  opts.on('--help', 'Display this screen' ) do
    puts ""
    puts "A Ruby implementation of the GNU coreutils wc command"
    puts ""
    puts opts
    exit
  end
end

def print_info(file_info)
  file_info.values.each do |value|
    print "\t#{value}"
  end
  puts ""
end

def get_bytes(file)
  File.size?(file)
end

def get_chars(file_text)
  num_of_chars = 0
  num_of_chars = file_text.split("").length
end

def get_lines(file_text)
  lines = 0
  lines = file_text.split("\n").length
end

def get_words(file_text)
  words = 0
  words = file_text.split.length
end

def parse_file(file, options)
  file_info = {}

  file_text = file.read

  # If no options passed other than input file/s
  # print lines, words, and chars for each file
  options[:input_file].nil?
  if options.values.all? {|option| true ^ option}
    file_info[:lines] = get_lines(file_text)
    file_info[:words] = get_words(file_text)
    file_info[:chars] = get_chars(file_text)

  # Otherwise print only specified options
  else
    if options[:bytes]
      file_info[:bytes] = get_bytes(file)
    end

    if options[:chars]
      file_info[:chars] = get_chars(file_text)
    end

    if options[:words]
      file_info[:words] = get_words(file_text)
    end

    if options[:lines]
      file_info[:lines] = get_lines(file_text)
    end

    if options[:max_line_length]
      max_length = 0
      file_text.split("\n").each do |line|
        length = line.length
        max_length = length if length > max_length
      end
      file_info[:max_line_length] = max_length
    end
  end
  file_info[:filename] = File.basename(file) unless $text_from_stdin
  return file_info
end

def load_file(file_name, sum_file_info, options)
  begin
    file = File.new(file_name.gsub("\n", ""), "r")
    file_info = parse_file(file, options)
    # Print output
    print_info(file_info)

    # Add new file to rolling sum
    file_info.keys.each do |key|
      sum_file_info[key] += file_info[key] unless key == (:filename || :max_line_length)
      if key == :max_line_length
        sum_file_info[key] = file_info[key] if file_info[key] > sum_file_info[key]
      end
    end
  rescue Exception => ex
    $error_message << "File '#{file_name}' could not be opened.\n"
    pp "An error of type #{ex.class} happened, message is #{ex.message}" if DEBUG
    pp ex.backtrace if DEBUG
  end

  return sum_file_info
end



# Begin main program

# Read in options
optparse.parse!

sum_file_info = {}
sum_file_info.default = 0

# wc.rb FILE
if options[:input_file].nil? && !ARGV.empty?

  # Accept more than one file passed at the command line
  ARGV.each do |file_name|
    sum_file_info = load_file(file_name, sum_file_info, options)
  end

  # Only show sums if more than one file is passed in from the command line
  if ARGV.length > 1
    sum_file_info[:total] = "total"
    print_info(sum_file_info)
  end

  puts $error_message unless $error_message.empty?

# wc.rb --files0-from=FILE_NAME OR wc.rb --files0-from=- (stdin)
elsif !options[:input_file].nil?

  # Either read lines from input file or read line of stdin for list of files
  files_list = options[:input_file].readlines

  # If file list came from stdin all file names are on one line...need to split
  files_list = files_list.first.split if $names_from_stdin

  files_list.each do |file_name|
    sum_file_info = load_file(file_name, sum_file_info, options)
  end

  # Print out sums
  if files_list.length > 1
    sum_file_info[:total] = "total"
    print_info(sum_file_info)
  end
  puts $error_message unless $error_message.empty?

# If stdin isn't empty read from there
else
  $text_from_stdin = true
  file_info = parse_file($stdin, options)
  # Print output
  print_info(file_info)
end
