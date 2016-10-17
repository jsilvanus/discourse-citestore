# name: Citestore
# about: Store citations and quote them with shorthand.
# version: 0.0.6
# authors: Juha Leinonen (jsilvanus)
# url: https://github.com/jsilvanus/discourse-citestore

enabled_site_setting :citestore_enabled

PLUGIN_NAME ||= "citestore".freeze
STORE_NAME ||= "citestorage".freeze

after_initialize do

  module ::Citestore
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace Citestore
    end
  end

  class Citestore::Storage
    class << self

      # Creation and deletion of storage; a store that holds all main handles
      def all(user_id)
        ensureStaff user_id
        storage = PluginStore.get(PLUGIN_NAME, STORE_NAME)

        return {} if storage.blank?
        storage
      end

      def exists(user_id, handle)
        storage = all(user_id)

        storage.include?(handle)
      end

      def create(user_id, handle)
        ensureStaff user_id

        raise StandardError.new "citestore.missing_handle" if handle.blank?

        storage = all(user_id)

        raise StandardError.new "citestore.disallowed_name" if ["defaults", "storage"].include?(handle)
        raise StandardError.new "citestore.already_exists" if storage.include?(handle)

        storage << handle
        PluginStore.set(PLUGIN_NAME, STORE_NAME, storage)
        Pluginstore.set(PLUGIN_NAME, handle, Hash.new)
        storage
      end

      def delete(user_id, handle)
        ensureStaff used_id

        raise StandardError.new "citestore.missing_handle" if handle.blank?
        raise StandardError.new "citestore.missing_storage" if exists(handle) == nil

        storage = all(user_id)
        storage.pop => handle
        PluginStore.remove(PLUGIN_NAME, handle)
        PluginStore.set(PLUGIN_NAME, STORE_NAME, storage)

        storage
      end

      # Get locus from storage
      def whole(handle)
        raise StandardError.new "citestore.missing_handle" if handle.blank?
        raise StandardError.new "citestore.missing_store" if exists(handle) == nil
        storage = PluginStore.get(PLUGIN_NAME, handle)

        storage
      end

      def has(handle, locus)
        raise StandardError.new "citestore.missing_handle" if handle.blank?
        raise StandardError.new "citestore.missing_locus" if locus.blank?
        storage = PluginStore.get(PLUGIN_NAME, handle)
        storage.has_key?(locus)
      end

      def get(handle, locus)
        raise StandardError.new "citestore.missing_handle" if handle.blank?
        raise StandardError.new "citestore.missing_store" if exists(handle) == nil

        storage = PluginStore.get(PLUGIN_NAME, handle)
        raise StandardError.new "citestore.missing_locus" if storage.has_key?(locus) == nil

        record = storage[locus]
        record
      end

      # Add locus to storage.
      def add(user_id, handle, locus, contents, force = nil)
        ensureStaff user_id

        raise StandardError.new "citestore.missing_handle" if handle.blank?
        raise StandardError.new "citestore.missing_locus" if locus.blank?
        raise StandardError.new "citestore.missing_content" if contents.blank?

        if exists(handle) == nil
          if force == nil
            raise StandardError.new "citestore.missing_store"
          end

          create(user_id, handle)
        end

        storage = PluginStore.get(PLUGIN_NAME, handle)
        storage[locus] = contents
        PluginStore.set(PLUGIN_NAME, handle, storage)

        contents
      end

      def remove(user_id, handle, locus)
        ensureStaff user_id

        if has(handle, locus)
          storage = PluginStore.get(PLUGIN_NAME, handle)
          storage.delete(locus)
          PluginStore.set(PLUGIN_NAME, handle, storage)
        end
      end

      # Ensure staff id
      def ensureStaff (user_id)
        user = User.find_by(id: user_id)

        unless user.try(:staff?)
          raise StandardError.new "citestore.must_be_staff"
        end
      end

    end
  end

  # Functionality, part 2
  require_dependency "application_controller"

  class Citestore::CitestoreController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_filter :ensure_logged_in

    # Storage creations
    def create
      handle   = params.require(:handle)
      user_id  = current_user.id

      begin
        record = Citestore::Storage.create(user_id, handle)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def delete
      handle = params.require(:handle)
      user_id  = current_user.id

      begin
        record = Citestore::Storage.delete(user_id, handle)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def all
      user_id  = current_user.id

      begin
        record = Citestore::Storage.all(user_id)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    # Loci
    def whole
      handle = params.require(:handle)
      user_id  = current_user.id

      begin
        record = Citestore::Storage.whole(user_id, handle)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def add
      handle = params.require(:handle)
      locus = params.require(:locus)
      content = params.require(:content)
      user_id = current_user.id

      begin
        record = Citestore::Storage.add(user_id, handle, locus, content)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def get
      handle = params.require(:handle)
      locus = params.require(:locus)
      user_id = current_user.id

      begin
        record = Citestore::Storage.get(user_id, handle, locus)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def default
      user_id = current_user.id

      begin
        Citestore::Storage.create(user_id, "test")
        Citestore::Storage.add(user_id, "test", "1", "Lorem ipsum...")
        Citestore::Storage.add(user_id, "test", "2", "...dolor sit amet.")
        record = Citestore::Storage.whole(user_id, "test")
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

  end

  # Routes

  Citestore::Engine.routes.draw do
    put "/" => "citestore#whole"
    get "/" => "citestore#get"
#    get "/:handle/:locus", to: 'citestore#get'
    post "/" => "citestore#add"
    delete "/" => "citestore#remove"

    post "/default" => "citestore#default"
    get "/default" => "citestore#default"

    get "/storage" => "citestore#all"
    post "/storage" => "citestore#create"
    delete "/storage" => "citestore#delete"
  end

  Discourse::Application.routes.append do
    mount ::Citestore::Engine, at: "/citestore"
  end

end
