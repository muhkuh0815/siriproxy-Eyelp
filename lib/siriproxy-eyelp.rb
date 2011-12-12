# -*- encoding: utf-8 -*-
require 'cora'
require 'siri_objects'
require 'eat'
require 'nokogiri'
require 'timeout'
require 'json'
require 'open-uri'
require 'uri'

#######
# 
# This is a plugin for Yelp-Searches outside the US.
# its for german, but should easily be adoptable for other languages.
#
# YOU NEED YOUR OWN YELP-API Key for your external IP address, maybe use your
# dyndns if you dont have a static IP.
# you can get a free trial Key for 100 requests per day here.
#    --->   http://www.yelp.com/developers
#
# Remember to add the plugin to the "/.siriproxy/config.yml" file!
# 
#######
#
# Das ist ein Plugin um Yelp-Suchen außerhalb der USA zu ermöglichen.
# ist natürlich in Deutsch, sollte aber einfach für andere Sprachen umzuschreiben sein. 
# 
# IHR BRAUCHT UNBEDINGT EINEN EIGENEN YELP-API KEY eurer externen IP Adresse, probiert
# es mit dyndns falls ihr keine statische IP habt.
# Ihr könnt hier einen Test Key für 100 Anfragen pro Tag anfordern
#    --->   http://www.yelp.com/developers
#
#
# Plugin in "/.siriproxy/config.yml" file hinzufügen !
#
#######
## ##  WIE ES FUNKTIONIERT
#
# "suche" + suchwort  = suche im Radius von 5 km
# 
# "suche" + suchwort + "in" + stadtname  = sucht in genannten Stadt
#
# "suche hier" + suchwort  = suche im Radius von 1 km
#
# "suche global" + suchwort  = suche im Radius von 25 km
#
# Beispiele: suche Hotel, suche global Mexikanisch, suche Hofbräuhaus in München,
# suche hier Würstelstand
#
#
# # # # Zusatzfunktion                - Additional Feature
# # # # Position Speichern und zeigen - save and show position
#
# "wo bin ich" = zeigt aktuelle position / shows current position
#
# "Position speichern" = speichert Position (zB Parkplatz)  / saves current Position (eg Parkingslot)
# "Position zeigen" = zeigt gespeicherte Position, aktuelle Position und Entfernung in km/meter  / shows saved Position, current Position and distance in kilometers
#
#
# bei Fragen Twitter: @muhkuh0815
# oder github.com/muhkuh0815/SiriProxy-Lotto
# pictures current version:  http://imageshack.us/photo/my-images/859/img0048vb.jpg/
# http://imageshack.us/photo/my-images/836/img0049xp.jpg/
#
# Video old version (without yelp-api): http://www.youtube.com/watch?v=sl726h6HckQ
#
#
####  Todo
#
#  sorting JSON hashes ... closest first
#  displaying red dot in the preview map - not sure if siriproxy supports that 
#  phone number in description 
#  ratings (maybe i put them after the name "Hotel Sacher - 4.5" until its supportet from siriproxy)
#
######


class SiriProxy::Plugin::Eyelp < SiriProxy::Plugin
        
    def initialize(config)
    	#####################################
    	                                    #
        $ywsid = "XXXXXXXXXXXXXXXXXXXXXX"   # insert your ywsid key here
                                            #
        #####################################
        # THIS KEY IS NEEDED - if you dont have one, request a free trial key here
        #               http://www.yelp.com/developers
        
        #if you have custom configuration options, process them here!
    end
    def doc
    end
    def docs
    end
    def dob
    end
    def maplo
    end
    def mapla
    end
    def doss
    end
            
    def cleanup(doc)
    doc = doc.to_s
 	doc = doc.gsub(/<\/?[^>]*>/, "")
 	return doc
 	end
    
	filter "SetRequestOrigin", direction: :from_iphone do |object|
    	puts "[Info - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}"
    	$maplo = object["properties"]["longitude"]
    	$mapla = object["properties"]["latitude"]
	end 


listen_for /suche (.*)/i do |phrase|
	parts = phrase.split
	len = parts.length
	i = 0
	while i < len do 
		print "------na---"
		print parts[i]
		if parts[i] == "in" #catching city-based search:  suche * in * 
			if i == 1
			part = parts[0]
			elsif i == 2
			part = parts[0] + " " + parts[1]
			elsif i == 3
			part = parts[0] + " " + parts[1] + " " + parts[2]
			elsif i == 4
			part = parts[0] + " " + parts[1] + " " + parts[2] + " " + parts[3]
			elsif i == 5
			part = parts[0] + " " + parts[1] + " " + parts[2] + " " + parts[3] + " " + parts[4]
			else
			part = phrase
			end
			leni = i
			leni += 1
			len = 99
			i = 100	
		end
		i += 1
	end
	pa1 = parts[0].strip
	begin
		if len >= 2 and pa1.strip == "hier"  # Range 1 Search
			if len == 2
				pa2 = parts[1].strip
			elsif len == 3
				pa2 = parts[1].strip + " " + parts[2].strip
			elsif len == 4
				pa2 = parts[1].strip + " " + parts[2].strip + " " + parts[3].strip
			else
				pa2 = parts[1].strip
			end
			dos = "http://api.yelp.com/business_review_search?term=" + pa2.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=1&limit=10&ywsid=" + $ywsid.to_s
		elsif len >= 2 and pa1.strip == "global"  # Range 25 Search
			if len == 2
				pa2 = parts[1].strip
			elsif len == 3
				pa2 = parts[1].strip + " " + parts[2].strip
			elsif len == 4
				pa2 = parts[1].strip + " " + parts[2].strip + " " + parts[3].strip
			else
				pa2 = parts[1].strip
			end
		dos = "http://api.yelp.com/business_review_search?term=" + pa2.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=25&limit=25&ywsid=" + $ywsid.to_s
		
		elsif len == 99 # City Search
		dos = "http://api.yelp.com/business_review_search?term=" + part + "&location=" + parts[leni].strip + "&limit=10&ywsid=" + $ywsid.to_s
		else # normal Search Radius 5
		dos = "http://api.yelp.com/business_review_search?term=" + phrase.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=5&limit=10&ywsid=" + $ywsid.to_s
		end
		dos = URI.parse(URI.encode(dos)) # allows Unicharacters in the search URL
		doc = Nokogiri::HTML(open(dos))
		doc.encoding = 'utf-8'
		doc = doc.text
   rescue Timeout::Error
     	doc = ""
    end
    if doc == ""
    	say "Bitte verwende 'suche' + 'lokal'", spoken: "Fehler beim Suchen" 
    	request_completed
    else
	json = doc.to_s
	empl = json
	empl.chop
	empl.reverse
	empl.chop
	empl.reverse
	empl.gsub('\"', '"')
	empl =JSON.parse(empl)
	busi = empl['businesses']
	if busi.empty? == true
		say "Keine Einträge in Yelp für '" + phrase + "' gefunden."
	else
	x = 0
	add_views = SiriAddViews.new
    add_views.make_root(last_ref_id)
    map_snippet = SiriMapItemSnippet.new(true)
	
	busi.each do |data|
		siri_location = SiriLocation.new(data['name'], data['address1'], data['city'], data['state_code'], data['country_code'], data['zip'].to_s , data['latitude'].to_s , data['longitude'].to_s) 
    	map_snippet.items << SiriMapItem.new(label=data['name'], location=siri_location, detailType="BUSINESS_ITEM")
 		x += 1
 	end
	
	if x.to_s == 1	
	say "Ich habe einen Eintrag gefunden."
	else	
	say "Ich habe " + x.to_s + " Einträge gefunden."
	end	
	print map_snippet.items
    utterance = SiriAssistantUtteranceView.new("")
    add_views.views << utterance
    add_views.views << map_snippet
    send_object add_views #send_object takes a hash or a SiriObject object
	end
	request_completed
end
end

# reading from a local JSON File ---- FOR TESTING
listen_for /(test|test eins)/i do    
	json = File.open("plugins/siriproxy-eyelp/jstest", "rb:utf-8")
	empl = json.read
	json.close
	empl.chop
	empl.reverse
	empl.chop
	empl.reverse
	empl.gsub('\"', '"')
	empl =JSON.parse(empl)
	busi = empl['businesses']
	x = 0
	add_views = SiriAddViews.new
    add_views.make_root(last_ref_id)
    map_snippet = SiriMapItemSnippet.new(true)
	
	busi.each do |data|
		siri_location = SiriLocation.new(data['name'], data['address1'], data['city'], data['state_code'], data['country_code'], data['zip'].to_s , data['latitude'].to_s , data['longitude'].to_s) 
    	map_snippet.items << SiriMapItem.new(label=data['name'], location=siri_location, detailType="FRIEND_ITEM") # BUSINESS_ITEM")
 		x += 1
 	end
	say "Ich habe " + x.to_s + " Einträge gefunden"
	print map_snippet.items
    utterance = SiriAssistantUtteranceView.new("")
    add_views.views << utterance
    add_views.views << map_snippet
    send_object add_views #send_object takes a hash or a SiriObject object
	request_completed
end


# safes position in a global variable
listen_for /(Position speichern)/i do   
	$ortla = $mapla
	$ortlo = $maplo
	say "aktueller Ort gespeichert, zum abrufen sage 'zeige Position'", spoken: "aktueller Ort gespeichert"
	#say "lat:" + $ortla.to_s + "  long:" + $ortlo.to_s , spoken: "" 
	request_completed 
end

# loads position from a global variable
listen_for /(zeige Ort|zeige Position|zeige gespeicherten Ort|Position zeigen|Position Info)/i do 
	if $ortla == NIL or $ortlo == NIL
		say "Keine Position gespeichert, verwende 'Position speichern'", spoken: "Keine Position gespeichert."
	else
	
	lon1 = 16.304431948726 #$ortlo #16.308673899999999 
	lat1 = 48.20761913432201 #$ortla #48.202757399999999 
	lon2 = $maplo
	lat2 = $mapla
	haversine_distance( lat1, lon1, lat2, lon2 )
	entf = @distances['km']
#	d = ""
#	if entf < 1 and entf > 0
#		entf = @distances['meters']
#		d = "m"
#	else
#		d = "k"
		entf = (entf * 10**3).round.to_f / 10**3
#	end
#	
	if entf.to_s == "0.0"
	say "Sie sind am Ziel angelangt."
	print entf
	elsif entf > 0.0 and entf < 1.000
	entf = (entf * 10**3).round.to_f / 10**3
	ent = ent.to_f
	ent = (entf * 1000)
	
	#ent = (ent * 10**0).round.to_f / 10**0
	say "Entfernung zum Ziel: " + ent.to_s + " m", spoken: "Entfernung zum Ziel: " + ent.to_s + " Meter"
	
	else
	say "Entfernung zum Ziel: " + entf.to_s + " km"
	end
	
	add_views = SiriAddViews.new
    add_views.make_root(last_ref_id)
    map_snippet = SiriMapItemSnippet.new(true)
    siri_location = SiriLocation.new("gepeicherter Ort" , "gepeicherter Ort", "gepeicherter Ort", "gepeicherter Ort", "durt", "wo", $ortla.to_f, $ortlo.to_s) 
    map_snippet.items << SiriMapItem.new(label="gespeicherter Ort", location=siri_location, detailType="BUSINESS_ITEM")
    print map_snippet.items
    utterance = SiriAssistantUtteranceView.new("Juhu, Ich habe mich gefunden!")
    #add_views.views << utterance
    add_views.views << map_snippet
    send_object add_views #send_object takes a hash or a SiriObject object
	end
	request_completed 

end


#    Thanks to http://www.esawdust.com/blog/businesscard/businesscard.html
# for the distance calculation code
def haversine_distance( lat1, lon1, lat2, lon2 )
	self::class::const_set(:RAD_PER_DEG, 0.017453293)
	self::class::const_set(:Rkm, 6371)              # radius in kilometers...some algorithms use 6367
	self::class::const_set(:Rmeters, 6371000)    # radius in meters
	@distances = Hash.new
	dlon = lon2 - lon1
	dlat = lat2 - lat1
	dlon_rad = dlon * RAD_PER_DEG
	dlat_rad = dlat * RAD_PER_DEG
	lat1_rad = lat1 * RAD_PER_DEG
	lon1_rad = lon1 * RAD_PER_DEG
	lat2_rad = lat2 * RAD_PER_DEG
	lon2_rad = lon2 * RAD_PER_DEG
	a = (Math.sin(dlat_rad/2))**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * (Math.sin(dlon_rad/2))**2
	c = 2 * Math.atan2( Math.sqrt(a), Math.sqrt(1-a))
	dKm = Rkm * c             # delta in kilometers
	dMeters = Rmeters * c     # delta in meters
	@distances["km"] = dKm
	@distances["m"] = dMeters
end


end
 
