#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

swiftgen_config="$root_dir/swiftgen.yml"
apple_resources="$root_dir/app-apple/Sources/AppStrings/Resources"
android_resources="$root_dir/app-android/app/src/main/res"

if ! command -v swiftgen >/dev/null 2>&1; then
    echo "error: swiftgen is not installed or not in PATH" >&2
    exit 1
fi

swiftgen config run --config "$swiftgen_config"

ruby - "$apple_resources" "$android_resources" <<'RUBY'
require "fileutils"

apple_resources = ARGV.fetch(0)
android_resources = ARGV.fetch(1)

class StringsParser
  def initialize(path)
    @path = path
    @text = File.read(path, encoding: "UTF-8")
    @index = 0
  end

  def parse
    entries = []
    skip_ignored

    until eof?
      key = parse_quoted_string
      skip_ignored
      expect("=")
      skip_ignored
      value = parse_quoted_string
      skip_ignored
      expect(";")
      entries << [key, value]
      skip_ignored
    end

    entries
  end

  private

  def eof?
    @index >= @text.length
  end

  def skip_ignored
    loop do
      @index += 1 while !eof? && @text[@index].match?(/\s/)

      if @text[@index, 2] == "//"
        @index += 2
        @index += 1 while !eof? && @text[@index] != "\n"
      elsif @text[@index, 2] == "/*"
        end_index = @text.index("*/", @index + 2)
        raise parse_error("unterminated block comment") unless end_index

        @index = end_index + 2
      else
        break
      end
    end
  end

  def parse_quoted_string
    expect("\"")
    output = +""

    until eof?
      char = @text[@index]
      @index += 1

      case char
      when "\""
        return output
      when "\\"
        output << parse_escape
      else
        output << char
      end
    end

    raise parse_error("unterminated quoted string")
  end

  def parse_escape
    raise parse_error("unfinished escape sequence") if eof?

    char = @text[@index]
    @index += 1

    case char
    when "n"
      "\n"
    when "r"
      "\r"
    when "t"
      "\t"
    when "\"", "'", "\\"
      char
    when "U", "u"
      hex = @text[@index, 4]
      raise parse_error("invalid unicode escape") unless hex&.match?(/\A[0-9a-fA-F]{4}\z/)

      @index += 4
      hex.to_i(16).chr(Encoding::UTF_8)
    else
      char
    end
  end

  def expect(token)
    actual = @text[@index, token.length]
    raise parse_error("expected #{token.inspect}, found #{actual.inspect}") unless actual == token

    @index += token.length
  end

  def parse_error(message)
    line = @text[0...@index].count("\n") + 1
    "#{@path}:#{line}: #{message}"
  end
end

def locale_for_lproj(dirname)
  File.basename(dirname, ".lproj")
end

def android_values_dir(locale)
  return "values" if locale == "en"

  parts = locale.split("-")
  return "values-#{locale}" if parts.length == 1
  return "values-#{parts[0]}-r#{parts[1]}" if parts.length == 2 && parts[1].match?(/\A[A-Z]{2}\z/)

  "values-b+#{parts.join("+")}"
end

def android_name(key)
  name = key.downcase
            .gsub(/[^a-z0-9_]+/, "_")
            .gsub(/_+/, "_")
            .gsub(/\A_+|_+\z/, "")

  name = "string_#{name}" if name.empty? || name.match?(/\A[0-9]/)
  name
end

FORMAT_PATTERN = /%([-+#0 ]*)(\d+|\*)?(?:\.(\d+|\*))?(hh|h|ll|l|z|t|j)?([@diuoxXfFeEgGaAcCsSp])/

def android_format_type(type)
  case type
  when "@", "s", "S"
    "s"
  when "d", "D", "i", "u", "U", "o", "x", "X"
    type == "X" ? "X" : "d"
  else
    type
  end
end

def convert_placeholders(value)
  index = 0
  output = +""
  cursor = 0

  while cursor < value.length
    percent = value.index("%", cursor)
    unless percent
      output << value[cursor..]
      break
    end

    output << value[cursor...percent]

    if value[percent + 1] == "%"
      output << "%%"
      cursor = percent + 2
      next
    end

    match = value.match(FORMAT_PATTERN, percent)
    if match && match.begin(0) == percent
      index += 1
      flags = match[1]
      width = match[2]
      precision = match[3] ? ".#{match[3]}" : ""
      type = android_format_type(match[5])
      output << "%#{index}$#{flags}#{width}#{precision}#{type}"
      cursor = match.end(0)
    else
      output << "%"
      cursor = percent + 1
    end
  end

  output
end

def placeholder_signature(value)
  signature = []
  cursor = 0

  while cursor < value.length
    percent = value.index("%", cursor)
    break unless percent

    if value[percent + 1] == "%"
      cursor = percent + 2
      next
    end

    match = value.match(FORMAT_PATTERN, percent)
    if match && match.begin(0) == percent
      signature << android_format_type(match[5])
      cursor = match.end(0)
    else
      cursor = percent + 1
    end
  end

  signature
end

def android_escape(value)
  convert_placeholders(value).each_char.map do |char|
    case char
    when "\n"
      "\\n"
    when "\r"
      "\\r"
    when "\t"
      "\\t"
    when "\\"
      "\\\\"
    when "'"
      "\\'"
    when "\""
      "\\\""
    when "&"
      "&amp;"
    when "<"
      "&lt;"
    when ">"
      "&gt;"
    else
      char
    end
  end.join
end

def parse_strings(path)
  entries = StringsParser.new(path).parse
  keys = {}

  entries.each do |key, _|
    raise "#{path}: duplicate key #{key.inspect}" if keys.key?(key)

    keys[key] = true
  end

  entries
end

def verify_locale!(locale, base_keys, locale_keys)
  missing = base_keys - locale_keys
  extra = locale_keys - base_keys
  return if missing.empty? && extra.empty?

  warn "error: #{locale} does not match en.lproj"
  warn "missing keys:\n#{missing.join("\n")}" unless missing.empty?
  warn "extra keys:\n#{extra.join("\n")}" unless extra.empty?
  exit 1
end

def verify_placeholders!(locale, base_entries, entries_by_key)
  mismatches = []

  base_entries.each do |key, base_value|
    base_signature = placeholder_signature(base_value)
    locale_signature = placeholder_signature(entries_by_key.fetch(key))
    next if base_signature == locale_signature

    mismatches << "#{key}: #{locale_signature.inspect} should be #{base_signature.inspect}"
  end

  return if mismatches.empty?

  warn "error: #{locale} placeholder signatures do not match en.lproj"
  warn mismatches.join("\n")
  exit 1
end

lproj_dirs = Dir.children(apple_resources)
                 .grep(/\.lproj\z/)
                 .sort_by { |dirname| locale_for_lproj(dirname) == "en" ? "" : dirname }
raise "no .lproj directories found in #{apple_resources}" if lproj_dirs.empty?

base_path = File.join(apple_resources, "en.lproj", "Localizable.strings")
base_entries = parse_strings(base_path)
base_keys = base_entries.map(&:first)
android_names = {}

base_keys.each do |key|
  name = android_name(key)
  if android_names.key?(name)
    raise "Android resource name collision: #{android_names[name].inspect} and #{key.inspect} both map to #{name.inspect}"
  end

  android_names[name] = key
end

lproj_dirs.each do |dirname|
  locale = locale_for_lproj(dirname)
  input_path = File.join(apple_resources, dirname, "Localizable.strings")
  entries_by_key = parse_strings(input_path).to_h
  verify_locale!(locale, base_keys, entries_by_key.keys)
  verify_placeholders!(locale, base_entries, entries_by_key)

  output_dir = File.join(android_resources, android_values_dir(locale))
  output_path = File.join(output_dir, "localizable.xml")
  xml = +"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
  xml << "<resources>\n"
  xml << "    <!-- Generated by scripts/gen-strings.sh. Do not edit directly. -->\n"

  base_keys.each do |key|
    xml << "    <string name=\"#{android_name(key)}\">#{android_escape(entries_by_key.fetch(key))}</string>\n"
  end

  xml << "</resources>\n"

  FileUtils.mkdir_p(output_dir)
  File.write(output_path, xml, encoding: "UTF-8")
end

puts "Generated SwiftGen bindings and Android string resources."
RUBY
