namespace :db do
  desc 'LF - rollback TC database to the specific commit'

  task :rollbacktc do
    puts 'Revert Test Central database to the specific commit'

    commit_id = ARGV[1]
    puts "Commit id: #{commit_id}"
    puts '======beginning reverting======'

    current_commit_id = `git log -1 --format=%h`.strip
    commit_migrate = `git show #{commit_id}:db/migrate`.split("\n")[-1]
    all_migrate_files = `git show #{current_commit_id}:db/migrate`.split("\n")
    index = all_migrate_files.index commit_migrate

    if index
      all_migrate_files[index + 1..-1].each { |m| puts `rake db:migrate:down VERSION=#{m[0..13]} SKIP_SCHEDULERS=1` }
    else
      puts 'No migration changes.'
    end

    # By default, rake considers each 'argument' to be the name of an actual task.
    # It will try to invoke each one as a task.  By dynamically defining a dummy
    # task for every argument, we can prevent an exception from being thrown
    # when rake inevitably doesn't find a defined task with that name.
    task commit_id.to_sym { ; } if commit_id

    puts 'done!'
  end
end
