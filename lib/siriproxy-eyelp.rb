# -*- encoding: utf-8 -*-
require 'cora'
require 'siri_objects'
require 'eat'
require 'nokogiri'
require 'timeout'
require 'json'
require 'open-uri'
require 'uri'
require 'siren' #for sorting json hashes

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
# "suche ____"  = suche __ im Radius von 5 km
# 
# "suche ____ in _____  = sucht ___ in der Stadt ____
#
# "suche hier _____"  = suche im Radius von 1 km
#
# "suche global _____"  = suche im Radius von 25 km
#
# Beispiele: suche ein Hotel, suche global Mexikanisch, suche Hofbräuhaus in München,
# suche hier Würstelstand
#
#
# # # # Zusatzfunktion - Additional Feature
#### Position Speichern und zeigen - save and show position
#
# "Wo bin ich" = zeigt aktuelle position / shows current position
#
# "Position speichern" = speichert Position (zB Parkplatz)  / saves current Position (eg Parkingslot)
# "Position zeigen" = zeigt gespeicherte Position, aktuelle Position und Entfernung in km/meter  / shows saved Position, current Position and distance in kilometers
#
#
# bei Fragen Twitter: @muhkuh0815
# oder github.com/muhkuh0815/SiriProxy-Lotto
# pictures current version:  http://imageshack.us/photo/my-images/859/img0048vb.jpg/
# http://imageshack.us/photo/my-images/836/img0049xp.jpg/
# Video Preview: http://www.youtube.com/watch?v=C3Qf9IKxoWQ
# Video old version (without yelp-api): http://www.youtube.com/watch?v=sl726h6HckQ
#
#
####  Todo
#
#  sorting JSON hashes ... closest first, sometimes it works with siren, sometimes it doenst
#  displaying red pin in the preview map - not sure if siriproxy supports that 
#  phone number in description 
#  ratings (maybe i put them after the name "Hotel Sacher - 4.5" until its supportet from siriproxy)
#  suche beste - search for the best
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
	ss = ""
	if $maplo == NIL 
		ss = "nogps"
	end
	#if phrase.match(/(ein )/)  # cleaning searchstring: eg:  ein hotel = hotel
	phrase = phrase.insert(0, " ")
	begin
	phrase = phrase.sub( " ein ", " " )
	phrase = phrase.sub( " eine ", " " )
	phrase = phrase.sub( " einen ", " " )
	phrase = phrase.sub( " den ", " " )
	phrase = phrase.sub( " das ", " " )
	phrase = phrase.sub( " die ", " " )
	rescue
	end
	if ss == "nogps"
		say "Kein GPS Signal - Ich suche in Wien", spoken: "Kein GPS Signal, Ich suche in Wien"
		phrase = phrase.sub( " in ", " " )
		phrase = phrase.sub( " hier ", " " )
		phrase = phrase.sub( " global ", " " )
		phrase = phrase.strip		
		dos = "http://api.yelp.com/business_review_search?term=" + phrase + "&location=Wien&limit=15&ywsid=" + $ywsid.to_s
		ss = "in"
	elsif phrase.match(/( hier )/)  # catching here search: suche hier *   :Range 1 
		ma = phrase.match(/( hier )/)
		part = ma.post_match.strip
		dos = "http://api.yelp.com/business_review_search?term=" + part.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=1&limit=10&ywsid=" + $ywsid.to_s
	elsif phrase.match(/( in )/) # catching city-based search:  suche * in *
		ma = phrase.match(/( in )/)	
		part2 = ma.post_match.strip
		part = ma.pre_match.strip
		dos = "http://api.yelp.com/business_review_search?term=" + part + "&location=" + part2 + "&limit=15&ywsid=" + $ywsid.to_s
		ss = "in"
	elsif phrase.match(/( global )/) # catching global search: suche global *   :Range 25
		ma = phrase.match(/( global )/)	
		part = ma.post_match.strip
		dos = "http://api.yelp.com/business_review_search?term=" + part.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=25&limit=25&ywsid=" + $ywsid.to_s
	else	# normal search: suche *   :Range 5
		phrase = phrase.strip
		part = phrase
		dos = "http://api.yelp.com/business_review_search?term=" + phrase.to_s + "&lat=" + $mapla.to_s + "&long=" + $maplo.to_s + "&radius=5&limit=15&ywsid=" + $ywsid.to_s
	end
	begin
		dos = URI.parse(URI.encode(dos)) # allows Unicharacters in the search URL
		doc = Nokogiri::HTML(open(dos))
		doc.encoding = 'utf-8'
		doc = doc.text
   	rescue Timeout::Error
     	doc = ""
    end
    if doc == ""
    	say "Bitte verwende 'suche' + suchparameter", spoken: "Fehler beim Suchen" 
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
		if ss == "in"
		say "Keine Einträge in Yelp für '" + part + "' in '" + part2 +"' gefunden."
		else
		say "Keine Einträge in Yelp für '" + part + "' gefunden."
		end
	else
		if ss == "in" #no sorting if city-search - to get best query on top
		else
			busi = Siren.query "$[ /@.distance ]", busi
		end
		x = 0
		add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
		busi.each do |data|
			sname = data['name'] + "-" + data['avg_rating'].to_s
			siri_location = SiriLocation.new(sname, data['address1'], data['city'], data['state_code'], data['country_code'], data['zip'].to_s , data['latitude'].to_s , data['longitude'].to_s) 
    		map_snippet.items << SiriMapItem.new(label=sname , location=siri_location, detailType="BUSINESS_ITEM")
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

# reading from the local "jstest" JSON File ---- FOR TESTING
listen_for /(testi|test eins)/i do    
	
	#teststring
	str = "Restaurant Il Sole Wiener Neustadt"
	
	if str.match(/(hier )/)
		ma = str.match(/(hier )/)
		print ma.post_match
	elsif str.match(/(in )/)
		mb = str.match(/(in )/)	
		print mb.pre_match.strip
		print "------"
		print mb.post_match.strip
	end
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
	busi = Siren.query "$[ /@.distance ]", busi
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

# Where am i - shows map with current location
listen_for /(Wo bin ich|Wo bist du)/i do
	if $mapla == NIL
    	say "Das wüßte ich auch gerne, aber ohne GPS Daten bin ich nur ein dummes Telefon."
    else
    	add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
 		siri_location = SiriLocation.new("", "Ich bin hier", "", "", "", "", $mapla.to_f, $maplo.to_s) 
	    map_snippet.items << SiriMapItem.new(label="Du bist hier", location=siri_location, detailType="BUSINESS_ITEM")
	    print map_snippet.items
	    utterance = SiriAssistantUtteranceView.new("hier")
		add_views.views << utterance
    	add_views.views << map_snippet
    
   		#you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
    	send_object add_views #send_object takes a hash or a SiriObject object
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

# safes position in the file "locsave.txt"
listen_for /(speicher Position|Position speichern|Position abspeichern|Position merken|Positionen speichern|speicher Positionen)/i do   
	lat = $mapla
	lon = $maplo
	if lat == nil
		say "Bitte schalten sie den Ortungsdienst ein."
	else
		lats = lat.to_s
		latt = lats.match(/[.]/)
		latt = latt.post_match.strip.size
		mystr = lat.to_s + "," + lon.to_s
		aFile = File.new("plugins/siriproxy-eyelp/locsave.txt", "w")
		aFile.write(mystr)
		aFile.close
		if latt < 13
			say "ungenaues GPS Signal - bitte nocheinmal speichern" 
		else
			say "aktueller Ort gespeichert, zum Abrufen sage 'zeige Position'", spoken: "aktueller Ort gespeichert"
		end
	end
	#say "lat:" + $ortla.to_s + "  long:" + $ortlo.to_s , spoken: "" 
	request_completed 
end

# loads position from a global variable
listen_for /(zeige Ort|zeige Position|zeige gespeicherten Ort|Position zeigen|Position anzeigen|Position zeige)/i do 
	aFile = File.new("plugins/siriproxy-eyelp/locsave.txt", "r")
	str = aFile.gets.to_s
	aFile.close
	if str.match(/(,)/)
		strloc = str.match(/(,)/)
		lat = strloc.pre_match
		lon = strloc.post_match
	end
	if lat.to_s == ""
		say "leeres File, verwende zuerst 'Position speichern'", spoken: "Ich habe keine gespeicherte Position gefunden."
	else
	lon1 = lon.to_f
	lat1 = lat.to_f
	lon2 = $maplo
	lat2 = $mapla
	if lon2 == NIL
		say "Bitte Ortungsdienst einschalten."
	else
		haversine_distance( lat1, lon1, lat2, lon2 )
		entf = @distances['km']
		entf = (entf * 10**3).round.to_f / 10**3
		if entf.to_s == "0.0"
			say "Sie sind am Ziel angelangt."
			print entf
		elsif entf > 0.0 and entf < 1.000
			entf = (entf * 10**3).round.to_f / 10**3
			ent = ent.to_f
			ent = (entf * 1000)
			ent = ent.to_s
			ent = ent.match(/(.)/)
			say "Entfernung zum Ziel: " + ent.to_s + " m", spoken: "Entfernung zum Ziel: " + ent.to_s + " Meter"
	
		else
			say "Entfernung zum Ziel: " + entf.to_s + " km"
		end
	
		add_views = SiriAddViews.new
    	add_views.make_root(last_ref_id)
    	map_snippet = SiriMapItemSnippet.new(true)
    	siri_location = SiriLocation.new("gepeicherter Ort" , "gepeicherter Ort", "gepeicherter Ort", "gepeicherter Ort", "durt", "wo", lat.to_f, lon.to_s) 
    	map_snippet.items << SiriMapItem.new(label="gespeicherter Ort", location=siri_location, detailType="BUSINESS_ITEM")
    	print map_snippet.items
    	utterance = SiriAssistantUtteranceView.new("Juhu, Ich habe mich gefunden!")
    #add_views.views << utterance
    	add_views.views << map_snippet
    	send_object add_views #send_object takes a hash or a SiriObject object
		end
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
 
