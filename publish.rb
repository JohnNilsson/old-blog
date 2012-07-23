require 'right_aws'

CONTENTDIR = 'compiled'
BUCKIT = 'curiousskeptic.com'
ENDPOINT = 's3-website-eu-west-1.amazonaws.com'


s3 = RightAws::S3.new(
	ENV['AMAZON_ACCESS_KEY_ID'],
	ENV['AMAZON_SECRET_ACCESS_KEY']
)

buckit = s3.bucket(BUCKIT)
keys = Hash[ buckit.keys.collect { |k| [k.name, k] }]

remote_files = keys.keys.to_set

local_files = Dir["#{CONTENTDIR}/**/*"].
	delete_if { |f| File.directory?(f) }.
	map { |f| f.gsub("#{CONTENTDIR}/",'')}.to_set


puts 'Add missing files'
(local_files - remote_files).each do |f|
	puts "Uploading new #{f}"
	buckit.put(f, open("#{CONTENTDIR}/#{f}"))
end

puts 'Update changed files'
(local_files & remote_files).each do |f|
	remote_md5 = keys[f].e_tag.gsub('"','').strip
	local_md5 =	Digest::MD5.hexdigest(File.read("#{CONTENTDIR}/#{f}"))	
	if remote_md5 == local_md5
		puts "Unchanged #{f}"
		next
	else
		puts "Uploading changed #{f} (#{remote_md5} != #{local_md5}})"
		buckit.put(f, open("#{CONTENTDIR}/#{f}"))
	end
end

puts 'Delete removed files'
(remote_files - local_files).each do |f|
	puts "Deleting removed #{f}"
	keys[f].delete
end