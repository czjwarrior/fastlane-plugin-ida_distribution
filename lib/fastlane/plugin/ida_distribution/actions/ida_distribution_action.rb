require 'fastlane/action'
require 'faraday'
require 'faraday_middleware'
require 'Plist'
require 'nokogiri'

require_relative '../helper/ida_distribution_helper'

module Fastlane
  module Actions
    class IdaDistributionAction < Action
      def self.run(params)
        UI.message("The ida_distribution plugin is working!")
        
#        ipa_path = params[:ipaPath]
#        ipaUrl = uploadFile(ipa_path, 'ipa')
#        result_plist_path = modifyPlist(params)
#        final_url = uploadFile(result_plist_path, 'plist')
        
        qrcodeUrl = generateQR("https://res.test.ida-it.com/resource-plist/b6cf748f6f4fbca9.plist")
        
        UI.success "Upload success. Visit this URL to see: #{qrcodeUrl}"
        
#        UI.success "Upload success. Visit this URL to see: #{final_url}"
        
      end
      
      def self.generateQR(plistUrl)
          
          itemServicesUrl = "itms-services://?action=download-manifest&url=#{plistUrl}"
          
          request = Faraday.new(
                  url: 'https://cli.im/api/qrcode/code',
                  params: {text: itemServicesUrl}
          )
          
          response = request.get
          
          info = response.body
          
          doc = Nokogiri::HTML response.body
          
          final = doc.xpath('//img')
          
          parserUrl = final[0]['src']
          
          qrcodeUrl = "http:#{parserUrl}"
          
          UI.message("=====#{qrcodeUrl}=====")
          
          return qrcodeUrl
          
      end
      
      def self.modifyPlist(params, ipaUrl)
          
          manifest_path = params[:manifestPath]
          app_version = params[:version]
          bundle_identifier = params[:bundleIdentifier]
          app_title = params[:title]
          
          path = File.join(manifest_path, "manifest.plist")
          result = Plist.parse_xml(path)
          
          items = result['items']
          item = items[0]

          assets = item['assets']
          metadata = item['metadata']

          asset = assets[0]
          ipaUrl = asset['url']
          asset['url'] = ipaUrl
          UI.message("=====ipa_url=#{ipaUrl}==============")
          
          metadata['bundle-version'] = app_version
          UI.message("=====app_version=#{app_version}==============")
          
          if app_title
              metadata['title'] = app_title
              UI.message("=====app_title=#{app_title}==============")
          end
          
          if bundle_identifier
              metadata['bundle-identifier'] = bundle_identifier
              UI.message("=====bundle_identifier=#{bundle_identifier}==============")
          end
          
          Plist::Emit.save_plist(result, path)
          
          return path
          
      end
      
      def self.uploadFile(filePath, fileType)
          api_host = "https://admin.test.ida-it.com/admin/content/oss/upload?fileType=#{fileType}"
          build_file = filePath
          
          UI.message "请求结果.... #{api_host}"
              
          if build_file.nil?
             UI.user_error!("You have to provide a build file")
          end
          
          UI.message "build_file: #{build_file}"
          
          # start upload
          conn_options = {
            request: {
              timeout:       1000,
              open_timeout:  300
            }
          }

          ida_client = Faraday.new(nil, conn_options) do |c|
            c.request :multipart
            c.request :url_encoded
            c.response :json, content_type: /\bjson$/
            c.adapter :net_http
          end
          
          params = {
              'file' => Faraday::UploadIO.new(build_file, 'application/octet-stream')
          }

          UI.message "Start upload #{build_file} to ida..."
          
          response = ida_client.post(api_host, params) do |req|
              req.headers['site'] = 'MAIN'
          end
          info = response.body
          
          UI.message "请求结果.... #{info}"

          if info['code'] != 200
            UI.user_error!("ida Plugin Error: #{info}")
          end
          
          UI.success "Upload success. Visit this URL to see: #{info['data']}"
          
          ipaUrl = info['data']
          
      end

      def self.description
        "upload ipa to ida platfrom"
      end

      def self.authors
        ["cenzhijun"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "upload ipa to ida platfrom"
      end

      def self.available_options
        [
        
            FastlaneCore::ConfigItem.new(key: :ipaPath,
                                              description: "ipa路径",
                                              is_string: true),
                                              
            FastlaneCore::ConfigItem.new(key: :manifestPath,
                                                description: "manifest.plist文件父目录",
                                                is_string: true),
                                                
            FastlaneCore::ConfigItem.new(key: :version,
                                                description: "版本号",
                                                is_string: true),
                                                
            FastlaneCore::ConfigItem.new(key: :bundleIdentifier,
                                                description: "唯一标识",
                                                optional: true,
                                                is_string: true),
                                                
            FastlaneCore::ConfigItem.new(key: :title,
                                                description: "APP名称",
                                                optional: true,
                                                is_string: true),
          # FastlaneCore::ConfigItem.new(key: :your_option,
          #                         env_name: "IDA_DISTRIBUTION_YOUR_OPTION",
          #                      description: "A description of your option",
          #                         optional: false,
          #                             type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
