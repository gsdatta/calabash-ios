class CoreIncluded
  include Calabash::Cucumber::Core
end

describe Calabash::Cucumber::Core do

  before {
    RunLoop::SimControl.terminate_all_sims
  }

  describe '#calabash_exit' do
    describe 'targeting simulators' do
      let(:launcher) { Calabash::Cucumber::Launcher.new }
      let(:core_instance) { CoreIncluded.new }

      Resources.shared.xcode_installs.each do |xcode_install|
        it "Xcode #{xcode_install.version_string}: #{xcode_install.path}" do
          sim_control = RunLoop::SimControl.new
          sim_control.reset_sim_content_and_settings
          options =
                {
                      :app => Resources.shared.app_bundle_path(:lp_simple_example),
                      :device_target =>  'simulator',
                      :sim_control => sim_control,
                      :launch_retries => Resources.shared.launch_retries
                }
          launcher.relaunch(options)
          expect(launcher.run_loop).not_to be == nil
          expect { core_instance.calabash_exit }.not_to raise_error
        end
      end
    end

    unless Resources.shared.travis_ci?
      describe 'targeting physical devices' do
        describe "Xcode #{Resources.shared.active_xcode_version}" do

          let(:launcher) { Calabash::Cucumber::Launcher.new }
          let(:core_instance) { CoreIncluded.new }

          xctools = RunLoop::XCTools.new
          physical_devices = Resources.shared.physical_devices_for_testing(xctools)

          if physical_devices.empty?
            it 'no devices attached to this computer' do
              expect(true).to be == true
            end
          elsif not Resources.shared.ideviceinstaller_available?
            it 'device testing requires ideviceinstaller to be available in the PATH' do
              expect(true).to be == true
            end
          else
            physical_devices.each do |device|
              if Luffa::Xcode.ios_version_incompatible_with_xcode_version?(device.version, xctools.xcode_version)
                it "Skipping #{device.name} iOS #{device.version} with Xcode #{xctools.xcode_version} - combination not supported" do
                  expect(true).to be == true
                end
              else
                it "on #{device.name} iOS #{device.version} Xcode #{xctools.xcode_version}" do
                  ENV['DEVICE_ENDPOINT'] = "http://#{device.name}.local:37265"
                  options =
                        {
                              :bundle_id => Resources.shared.bundle_id,
                              :udid => device.udid,
                              :device_target => device.udid,
                              :sim_control => RunLoop::SimControl.new,
                              :launch_retries => Resources.shared.launch_retries
                        }

                  expect {
                    Resources.shared.ideviceinstaller.install(device.udid)
                  }.to_not raise_error

                  launcher.relaunch(options)
                  expect(launcher.run_loop).not_to be == nil
                  expect { core_instance.calabash_exit }.not_to raise_error
                end
              end
            end
          end
        end
      end

      describe 'Xcode regression' do
        let(:launcher) { Calabash::Cucumber::Launcher.new }
        let(:core_instance) { CoreIncluded.new }

        xcode_installs = Resources.shared.alt_xcode_details_hash
        xctools = RunLoop::XCTools.new
        physical_devices = Resources.shared.physical_devices_for_testing(xctools)
        if not xcode_installs.empty? and Resources.shared.ideviceinstaller_available? and not physical_devices.empty?
          xcode_installs.each do |install_hash|
            version = install_hash[:version]
            path = install_hash[:path]
            physical_devices.each do |device|
              if Luffa::Xcode.ios_version_incompatible_with_xcode_version?(device.version, version)
                it "Skipping #{device.name} iOS #{device.version} with Xcode #{version} - combination not supported" do
                  expect(true).to be == true
                end
              else
                it "Xcode #{version} @ #{path} #{device.name} iOS #{device.version}" do
                  ENV['DEVELOPER_DIR'] = path
                  ENV['DEVICE_ENDPOINT'] = "http://#{device.name}.local:37265"
                  options =
                        {
                              :bundle_id => Resources.shared.bundle_id,
                              :udid => device.udid,
                              :device_target => device.udid,
                              :sim_control => RunLoop::SimControl.new,
                              :launch_retries => Resources.shared.launch_retries
                        }

                  expect {
                    Resources.shared.ideviceinstaller.install(device.udid)
                  }.to_not raise_error

                  launcher.relaunch(options)
                  expect(launcher.run_loop).not_to be == nil
                  expect { core_instance.calabash_exit }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end
end
