require 'rubygems'
require 'appium_lib'
require 'rest_client' # https://github.com/archiloque/rest-client
require 'json' # for .to_json


### Local ###
appium_capabilities = { launchTimeout: 300000}
apk = {
    caps: {
        name: 'Mobile test',
        launchTimeout: '300000',
        newCommandTimeout: '600',
        #fullReset: true,
        #noReset: false,
        platformName: 'Android',
        deviceName: 'Android Emulator',
        platformVersion: '4.2',
        "appium-version" => '1.0',
        app:'sauce-storage:RakutenShipping.apk',
        locationServicesEnabled: false
    },
    appium_lib: {
        server_url: "http://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@ondemand.saucelabs.com:80/wd/hub",
        wait: 60,
        sauce_username: ENV['SAUCE_USERNAME'],
        sauce_access_key: ENV['SAUCE_ACCESS_KEY'],
        debug: true
    }
}

Before do |scenario|
  begin
    apk[:caps][:name] = scenario.name
    Appium::Driver.new(apk).start_driver
    Appium.promote_appium_methods Object

  rescue Exception => e
    puts "********** CAUGHT AN EXCEPTION ****************************************************************"
    puts "Feature: #{scenario.feature.short_name} : Scenario Name: #{scenario.name}"
    puts e.message
    puts "***********************************************************************************************"
    driver_quit
  end
end

$passed = true

After do |scenario|
  $passed = ! scenario.failed?
  # Reset scenario unless the feature was tagged @keep
  #doesn't work### $driver.execute_script 'mobile: reset' unless scenario.feature.source_tag_names.include? '@keep'

  # selenium-webdriver (2.32.1) or better can use
  # $driver.driver.session_id
  id = $driver.driver.send(:bridge).session_id

  ignore {$driver.x}

  URL = "https://#{ENV['SAUCE_USERNAME']}:#{ENV['SAUCE_ACCESS_KEY']}@saucelabs.com/rest/v1/#{ENV['SAUCE_USERNAME']}/jobs/#{id}"

  puts URL
  # Keep trying until passed is set correctly. Give up after 30 seconds.
  wait_true do
    response = RestClient.put URL, { 'passed' => $passed }.to_json, :content_type => :json, :accept => :json
    response = JSON.parse(response)

    # Check that the server responded with the right value.
    response['passed'] == $passed
  end
end

at_exit do
end
