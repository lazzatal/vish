# encoding: utf-8
STATS_FILE_PATH = "reports/stats.txt";

namespace :stats do

  #Usage
  #Development:   bundle exec rake stats:all
  task :all => :environment do
    Rake::Task["stats:prepare"].invoke
    Rake::Task["stats:excursions"].invoke(false)
    Rake::Task["stats:resources"].invoke(false)
    Rake::Task["stats:users"].invoke(false)
  end

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
  end

  #Usage
  #Development:   bundle exec rake stats:excursions
  task :excursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Excursions Stats"

    allDates = [];
    allExcursions = [];
    for year in 2012..2016
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        excursions = Excursion.where(:created_at => startDate..endDate)
        allDates.push(startDate.strftime("%B %Y"));
        allExcursions.push(excursions);
      end
    end

    #Created excursions
    createdExcursions = []
    accumulativeCreatedExcursions = []
    publishedExcursions = []
    allExcursions.each_with_index do |excursions,index|
      nCreated = excursions.order('id DESC').first.id rescue 0
      accumulativeCreatedExcursions.push(nCreated)
      nCreated = (nCreated - accumulativeCreatedExcursions[index-1]) unless index==0 or nCreated == 0
      createdExcursions.push(nCreated)
      publishedExcursions.push(excursions.count)
    end

    #Accumulative Published Excursions
    accumulativePublishedExcursions = [];
    publishedExcursions.each_with_index do |n,index|
      accumulativePublishedExcursions.push(n)
      accumulativePublishedExcursions[index] = accumulativePublishedExcursions[index] + accumulativePublishedExcursions[index-1] unless index==0
    end

    filePath = "reports/excursions_stats.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Presentations Stats") do |sheet|
        rows = []
        rows << ["Presentations Stats"]
        rows << ["Date","Created Presentations","Published Presentations","Accumulative Created Presentations","Accumulative Published Presentations"]
        rowIndex = rows.length
        
        rows += Array.new(createdExcursions.length).map{|e|[]}
        createdExcursions.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],createdExcursions[i],publishedExcursions[i],accumulativeCreatedExcursions[i],accumulativePublishedExcursions[i]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end
      prepareFile(filePath)
      p.serialize(filePath)

      puts("Task Finished. Results generated at " + filePath)
    end

  end

  task :resources, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Resources Report")
    writeInStats("")

    allCreatedResources = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        resources = Document.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allCreatedResources.push(resources);
      end
    end

    writeInStats("")
    writeInStats("Created Resources")
    allCreatedResources.each do |createdResources|
      writeInStats(createdResources.count)
    end

    writeInStats("")
    writeInStats("Accumulative Created Resources")
    accumulativeResources = 0;
    allCreatedResources.each do |createdResources|
      accumulativeResources = accumulativeResources + createdResources.count
      writeInStats(accumulativeResources)
    end

    #Resources type
    writeInStats("")
    writeInStats("Type of Resources")
    resourcesReport = getResourcesByType(Document.all)

    resourcesReport.each do |resourceReport|
      writeInStats(resourceReport["resourceType"].to_s);
      writeInStats(resourceReport["percent"].to_s)
    end

  end

  task :users, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Users Report")
    writeInStats("")

    allUsers = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        users = User.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allUsers.push(users);
      end
    end

    writeInStats("")
    writeInStats("Registered Users")
    allUsers.each do |users|
      writeInStats(users.count)
    end

    writeInStats("")
    writeInStats("Accumulative Registered Users")
    accumulativeUsers = 0;
    allUsers.each do |users|
      accumulativeUsers = accumulativeUsers + users.count
      writeInStats(accumulativeUsers)
    end

  end

  def getResourcesByType(resources)
    results = [];
    resourcesType = Hash.new;
    #resourcesType['file_content_type'] = [resources];

    resources.each do |resource|
      if resource.file_content_type
        if resourcesType[resource.file_content_type] == nil
          resourcesType[resource.file_content_type] = [];
        end
        resourcesType[resource.file_content_type].push(resource);
      end
    end

    resourcesType.each do |e|
      key = e[0]
      value = e[1]

      result = Hash.new;
      result["resourceType"] = key;
      result["percent"] = ((value.count/resources.count.to_f)*100).round(3);
      results.push(result);
    end

    results
  end

  def writeInStats(line)
    write(line,STATS_FILE_PATH)
  end

end
