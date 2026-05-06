SimpleCov.use_merging false
SimpleCov.start do
  enable_coverage :branch
  coverage_dir 'coverage/ruby'
  add_filter '/test/'
end
