require_relative "types"
require_relative "renderer/html"

class RepoDoctorCLI
  ANALYZERS_DIR = File.join(__dir__, "analyzers")

  def self.discover_analyzers
    Dir.glob(File.join(ANALYZERS_DIR, "*.rb")).filter_map do |file|
      next if File.basename(file) == "base.rb"
      require file
      basename = File.basename(file, ".rb")
      class_name = basename.split("_").map(&:capitalize).join + "Analyzer"
      klass = Object.const_get(class_name) rescue nil
      klass&.new
    end
  end

  def self.run(args)
    if args.empty? || args.include?("--help")
      puts "Usage: repo-doctor <repo-path> [--output report.html] [--analyzer <name>]"
      exit(args.include?("--help") ? 0 : 1)
    end

    repo_path = args[0]
    output_idx = args.index("--output")
    output_path = output_idx ? args[output_idx + 1] : nil
    analyzer_idx = args.index("--analyzer")
    analyzer_filter = analyzer_idx ? args[analyzer_idx + 1] : nil

    analyzers = discover_analyzers

    if analyzer_filter
      analyzers = analyzers.select { |a| a.name == analyzer_filter }
      if analyzers.empty?
        $stderr.puts "Unknown analyzer: #{analyzer_filter}"
        exit 1
      end
    end

    puts "Running #{analyzers.length} analyzer(s) against #{repo_path}...\n\n"

    results = analyzers.map do |analyzer|
      puts "  Running: #{analyzer.name}..."
      result = analyzer.run(repo_path)
      puts "  #{analyzer.name}: score #{result.score}/100 (#{result.findings.length} findings)"
      result
    end

    if output_path
      html = ReportRenderer.render(results)
      File.write(output_path, html)
      puts "\nReport written to #{output_path}"
    else
      puts "\n--- Results ---\n\n"
      results.each do |r|
        puts "#{r.analyzer}: #{r.score}/100"
        r.findings.each do |f|
          line_str = f.line ? ":#{f.line}" : ""
          puts "  [#{f.severity}] #{f.file}#{line_str} — #{f.message}"
        end
      end
    end
  end
end
