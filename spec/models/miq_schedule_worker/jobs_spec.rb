RSpec.describe MiqScheduleWorker::Jobs do
  context "#ems_refresh_timer" do
    it "with no EMSes" do
      described_class.new.ems_refresh_timer(ManageIQ::Providers::Vmware::InfraManager)

      expect(MiqQueue.count).to eq(0)
    end

    it "with an EMS" do
      zone = EvmSpecHelper.local_miq_server.zone
      FactoryBot.create(:ems_vmware, :zone => zone)
      described_class.new.ems_refresh_timer(ManageIQ::Providers::Vmware::InfraManager)

      expect(MiqQueue.count).to eq(1)
      expect(MiqQueue.first).to have_attributes(
        :class_name  => "ManageIQ::Providers::Vmware::InfraManager",
        :instance_id => nil,
        :method_name => "refresh_all_ems_timer",
        :zone        => zone.name
      )
    end
  end

  describe "#miq_schedule_queue_scheduled_work" do
    require "rufus-scheduler"

    it "delegates the queueing to MiqSchedule" do
      Timecop.freeze do
        schedule_id = 123
        scheduler = Rufus::Scheduler.new
        block = -> { "some work" }
        rufus_job = Rufus::Scheduler::EveryJob.new(scheduler, 1.hour.to_i, {}, block)

        expect(MiqSchedule).to receive(:queue_scheduled_work).with(schedule_id, rufus_job.job_id, 1.hour.from_now.to_i, {})

        described_class.new.miq_schedule_queue_scheduled_work(schedule_id, rufus_job)
      end
    end
  end

  describe "#generate_chargeback_for_service" do
    it "queue request to generate Chargeback reports for each service" do
      allow(MiqServer).to receive(:my_zone)
      described_class.new.generate_chargeback_for_service(:report_source => "Rspec - Chargeback reports queue")
      expect(MiqQueue.first).to have_attributes(
        :class_name  => "Service",
        :method_name => "queue_chargeback_reports",
        :args        => [{:report_source => "Rspec - Chargeback reports queue"}]
      )
    end
  end

  describe "#check_for_timed_out_active_tasks" do
    it "enqueues update_status_for_timed_out_active_tasks" do
      allow(MiqServer).to receive(:my_zone)
      described_class.new.check_for_timed_out_active_tasks
      expect(MiqQueue.first).to have_attributes(
        :class_name  => "MiqTask",
        :method_name => "update_status_for_timed_out_active_tasks"
      )
    end
  end

  context "with guid, server, zone" do
    let!(:server) { EvmSpecHelper.local_miq_server }
    let(:guid) { server.guid }
    let(:zone) { server.zone }

    context "queues for miq_server process" do
      it "#vmdb_database_connection_log_statistics" do
        described_class.new.vmdb_database_connection_log_statistics
        expect(MiqQueue.where(:method_name => "log_statistics").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
      end

      it "#miq_server_audit_managed_resources" do
        described_class.new.miq_server_audit_managed_resources
        expect(MiqQueue.where(:method_name => "audit_managed_resources").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
      end

      it "#miq_server_status_update" do
        described_class.new.miq_server_status_update
        expect(MiqQueue.where(:method_name => "status_update").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
      end

      it "#miq_server_worker_log_status" do
        described_class.new.miq_server_worker_log_status
        expect(MiqQueue.where(:method_name => "log_status").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
        expect(MiqQueue.where(:method_name => "log_status_all").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
      end

      it "#vmdb_appliance_log_config" do
        described_class.new.vmdb_appliance_log_config
        expect(MiqQueue.where(:method_name => "log_config").first).to have_attributes(:queue_name => "miq_server", :server_guid => guid, :zone => zone.name)
      end
    end
  end
end
