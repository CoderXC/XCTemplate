require 'fileutils'
require 'colored2'

module Pod
  class TemplateConfigurator

    attr_reader :pod_name, :string_replacements

    #初始化配置脚本
    def initialize(pod_name)
      @pod_name = pod_name
    end

    #运行脚本
    def run
      puts "-------------创建项目开始-----------------"
      #需要替换的内容
      @string_replacements = {
        "TODAYS_DATE" => date,
        "TODAYS_YEAR" => year,
        "PROJECT" => @pod_name,
        "CPD" => 'XC'
      }
      #对包含的内容进行替换
      replace_internal_project_settings

      #重命名文件名
      rename_files

      #重命名工程目录文件名
      rename_project_folder

      #替换podfile内的工程名
      replace_variables_in_Podfiles
      
      #删除脚本文件
      clean_ruby_files

      #移除git初始化
      remove_git_repo

      #执行pod install
      run_pod_install

      puts "-------------创建项目完成-----------------"

    end

    #获取工程所在路径
    def project_folder
      File.dirname "PROJECT.xcodeproj"
    end
    
    def replace_internal_project_settings

      Dir.glob(project_folder + "/**/**/**/**").each do |name|
        next if Dir.exists? name
        text = File.read(name)
        
        for find, replace in @string_replacements
            text = text.gsub(find, replace)
        end

        File.open(name, "w") { |file| file.puts text }
      end
    end

    def replace_variables_in_Podfiles
      file_names = ["./Podfile"]
      file_names.each do |file_name|
        text = File.read(file_name)
        text.gsub!("${POD_NAME}", @pod_name)
        File.open(file_name, "w") { |file| file.puts text }
      end
    end
    
    def rename_files
      # shared schemes have project specific names
      scheme_path = project_folder + "/PROJECT.xcodeproj/xcshareddata/xcschemes/"
      File.rename(scheme_path + "PROJECT.xcscheme", scheme_path +  @pod_name + ".xcscheme")

      # rename xcproject
      File.rename(project_folder + "/PROJECT.xcodeproj", project_folder + "/" +  @pod_name + ".xcodeproj")

      # change app file prefixes
      ["CPDAppDelegate.h", "CPDAppDelegate.m", "CPDViewController.h", "CPDViewController.m"].each do |file|
        before = project_folder + "/PROJECT/" + file
        next unless File.exists? before

        after = project_folder + "/PROJECT/" + file.gsub("CPD", "XC")
        File.rename before, after
      end

      # rename project related files
      ["PROJECT-Info.plist", "PROJECT-Prefix.pch", "PROJECT.entitlements"].each do |file|
        before = project_folder + "/PROJECT/" + file
        next unless File.exists? before

        after = project_folder + "/PROJECT/" + file.gsub("PROJECT",@pod_name)
        File.rename before, after
      end
    end

    def rename_project_folder
      if Dir.exist? project_folder + "/PROJECT"
        File.rename(project_folder + "/PROJECT", project_folder + "/" + @pod_name)
      end
    end

    def clean_ruby_files
      ["configure", "setup"].each do |asset|
        `rm -rf #{asset}`
      end
    end

    def remove_git_repo
      `rm -rf .git`
    end

    def run_pod_install
      system "pod install"
    end

    #----------------------------------------#

    def year
      Time.now.year.to_s
    end

    def date
      Time.now.strftime "%m/%d/%Y"
    end
    #----------------------------------------#
  end
end
