require 'rubygems'
require 'json'
require 'typhoeus'
require 'to_bool'

class Crumbs

	attr_accessor :item_crumbs, :epf_item_crumbs, :floors_crumbs, :stamps_crumbs, :postcard_crumbs, :igloo_crumbs, :furniture_crumbs, :room_crumbs, :game_room_crumbs

	def initialize(main_class)
		@parent = main_class
		@urls = {
			'rooms' => 'http://127.0.0.1/website/JSONS/rooms.json',
			'stamps' => 'http://127.0.0.1/website/JSONS/stamps.json',
			'postcards' => 'http://127.0.0.1/website/JSONS/postcards.json',
			'items' => 'http://127.0.0.1/website/JSONS/paper_items.json',
			'igloos' => 'http://127.0.0.1/website/JSONS/igloos.json',
			'floors' => 'http://127.0.0.1/website/JSONS/igloo_floors.json',
			'furniture' => 'http://127.0.0.1/website/JSONS/furniture_items.json'
		}	
		@item_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@epf_item_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@floors_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@stamps_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@postcard_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@igloo_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@furniture_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@room_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
		@game_room_crumbs = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
	end
	
	def loadCrumbs
		crumbs_data = {}
		hydra = Typhoeus::Hydra.new
		@urls.each do |crumbs_type, crumbs_url|
			request = Typhoeus::Request.new(crumbs_url)
			request.on_complete do |response|
				if response.success?
					crumbs_data[crumbs_type] = response.body
				else
					@parent.logger.error('Failed to get url: ' + crumbs_url)
				end
			end
			hydra.queue(request)
		end
		hydra.run 
		crumbs_data.each do |crumbs_name, crumbs_data|
			case crumbs_name
				when 'items'
					self.loadItems(crumbs_data)
				when 'floors'
					self.loadFloors(crumbs_data)
				when 'stamps'
					self.loadStamps(crumbs_data)
				when 'postcards'
					self.loadPostcards(crumbs_data)
				when 'igloos'
					self.loadIgloos(crumbs_data)
				when 'furniture'
					self.loadFurnitures(crumbs_data)
				when 'rooms'
					self.loadRooms(crumbs_data)
			end
		end
	end
	
	def loadItems(crumbs_data)
		decoded_items_data = JSON.parse(crumbs_data)
		decoded_items_data.each do |item|
			if item['is_epf'].to_bool == true
				@epf_item_crumbs[item['paper_item_id']] = ['points' => item['cost']]
			else 
				@item_crumbs[item['paper_item_id']] = ['price' => item['cost']]
			end
		end	
		@parent.logger.info('Successfully loaded ' + @epf_item_crumbs.count.to_s + ' EPF Items')
		@parent.logger.info('Successfully loaded ' + @item_crumbs.count.to_s + ' Items')
	end
	
	def loadFloors(crumbs_data)
		decoded_floors_data = JSON.parse(crumbs_data)
		decoded_floors_data.each do |floor|
			@floors_crumbs[floor['igloo_floor_id']] = ['price' => floor['cost']]	
		end
		@parent.logger.info('Successfully loaded ' + @floors_crumbs.count.to_s + ' Floors')
	end
	
	def loadStamps(crumbs_data)
		decoded_stamps_data = JSON.parse(crumbs_data)
		decoded_stamps_data.each do |first_stamps_index, value_one|
			first_stamps_index.each do |value_two, value_three|
				if value_three.respond_to?('each')
					value_three.each do |stamps|
						@stamps_crumbs[stamps['stamp_id']] = ['rank' => stamps['rank']]
					end
				end
			end
		end
		@parent.logger.info('Successfully loaded ' + @stamps_crumbs.count.to_s + ' Stamps')
	end
	
	def loadPostcards(crumbs_data)
		decoded_pcards_data = JSON.parse(crumbs_data)
		decoded_pcards_data.each do |card_id, card_cost|
			@postcard_crumbs[card_id] = ['cost' => card_cost]
		end
		@parent.logger.info('Successfully loaded ' + @postcard_crumbs.count.to_s + ' Postcards')
	end
	
	def loadIgloos(crumbs_data)
		decoded_igloos_data = JSON.parse(crumbs_data)
		decoded_igloos_data.each do |igloo_index, igloo|
			@igloo_crumbs[igloo['igloo_id']] = ['price' => igloo['cost']]	
		end
		@parent.logger.info('Successfully loaded ' + @igloo_crumbs.count.to_s + ' Igloos')
	end
	
	def loadFurnitures(crumbs_data)
		decoded_furns_data = JSON.parse(crumbs_data)
		decoded_furns_data.each do |furn|
			@furniture_crumbs[furn['furniture_item_id']] = ['price' => furn['cost']]	
		end
		@parent.logger.info('Successfully loaded ' + @furniture_crumbs.count.to_s + ' Furnitures')
	end
	
	def loadRooms(crumbs_data)
		decoded_rooms_data = JSON.parse(crumbs_data)
		decoded_rooms_data.each do |room_index|
			room_index.each do |room|
				if room['room_key'] != ''
					@room_crumbs[room['room_id']] = ['name' => room['room_key'], 'max' => room['max_users']]	
				else
					@game_room_crumbs[room['room_id']] = ['max' => room['max_users']]
				end
			end
		end
		@parent.logger.info('Successfully loaded ' + @room_crumbs.count.to_s + ' Rooms')
		@parent.logger.info('Successfully loaded ' + @game_room_crumbs.count.to_s + ' Game Rooms')
	end

end
