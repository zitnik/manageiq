class PhysicalServerProfile < ApplicationRecord
  acts_as_miq_taggable

  # TODO which ones of these are really needed? (copied from physical_server)
  include NewWithTypeStiMixin
  include MiqPolicyMixin
  include TenantIdentityMixin
  include SupportsFeatureMixin
  include EventMixin
  include ProviderObjectMixin
  include ComplianceMixin
  include EmsRefreshMixin

  belongs_to :ext_management_system, :foreign_key => :ems_id, :inverse_of => :physical_server_profiles,
    :class_name => "ManageIQ::Providers::PhysicalInfraManager"

  belongs_to :assigned_server, :foreign_key => :assigned_server_id, :optional => true, :class_name => "ManageIQ::Providers::PhysicalInfraManager::PhysicalServer"
  belongs_to :associated_server, :foreign_key => :associated_server_id, :optional => true, :class_name => "ManageIQ::Providers::PhysicalInfraManager::PhysicalServer"

end
