require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task default: [:test]

task :clean do
  `rm -rf coverage/*`
  `find ./ -name \\*~ -delete`
end

task test: [:clean]

task stats: :clean do
  count_non_empty_lines_on = Proc.new do |file|
    `find #{file} -exec cat {} \\; |sed /^\w*$/d |wc -l`.to_i
  end

  lloc  = count_non_empty_lines_on['./lib/  -type f \\( -iname "*.rb" \\)']
  tloc  = count_non_empty_lines_on['./test/ -type f \\( -iname "*.rb"' +
                                   ' -and ! -wholename "./test/support/*" \\)']
  ratio = tloc.to_f / lloc

  puts "Code LOC: #{lloc}\tTest LOC: #{tloc}\tCode to Test Ratio: 1:%.2f" % ratio
end
