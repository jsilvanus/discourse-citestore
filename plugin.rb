# name: Citestore
# about: Store citations and quote them with shorthand.
# version: 0.0.1
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

        raise StandardError.new "citestore.create.nohandle" if handle.blank?

        storage = all(user_id)
        raise StandardError.new "citestore.create.already_exists" if storage.include?(handle)

        storage << handle
        PluginStore.set(PLUGIN_NAME, STORE_NAME, storage)
        Pluginstore.set(PLUGIN_NAME, handle, Hash.new)
        storage
      end

      def delete(user_id, handle)
        ensureStaff used_id

        raise StandardError.new "citestore.delete.nohandle" if handle.blank?
        raise StandardError.new "citestore.delete.nostorage" if exists(handle) == nil

        storage = all(user_id)
        storage.pop => handle
        PluginStore.remove(PLUGIN_NAME, handle)
        PluginStore.set(PLUGIN_NAME, STORE_NAME, storage)

        storage
      end

      # Get locus from storage
      def whole(handle)
        raise StandardError.new "citestore.whole.nohandle" if handle.blank?
        raise StandardError.new "citestore.whole.nostore" if exists(handle) == nil
        storage = PluginStore.get(PLUGIN_NAME, handle)

        storage
      end

      def has(handle, locus)
        raise StandardError.new "citestore.has.nohandle" if handle.blank?
        raise StandardError.new "citestore.has.nolocus" if locus.blank?
        storage = PluginStore.get(PLUGIN_NAME, handle)
        storage.has_key?(locus)
      end

      def get(handle, locus)
        raise StandardError.new "citestore.get.nohandle" if handle.blank?
        raise StandardError.new "citestore.get.nostore" if exists(handle) == nil

        storage = PluginStore.get(PLUGIN_NAME, handle)
        raise StandardError.new "citestore.get.nolocus" if storage.has_key?(locus) == nil

        record = storage[locus]
        record
      end

      # Add locus to storage.
      def add(user_id, handle, locus, contents, force = nil)
        ensureStaff user_id

        raise StandardError.new "citestore.add.nohandle" if handle.blank?
        raise StandardError.new "citestore.add.nolocus" if locus.blank?
        raise StandardError.new "citestore.add.nocontents" if contents.blank?

        if exists(handle) == nil
          if force == nil
            raise StandardError.new "citestore.add.nostore"
          end

          create(user_id, handle)
        end

        storage = PluginStore.get(PLUGIN_NAME, handle)
        storage[locus] = contents

        contents
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

  # Continue here...
end
