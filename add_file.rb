require 'xcodeproj'

project_path = 'GeoAdvanture.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'GeoAdvanture' }
group = project.main_group['GeoAdvanture']

if group
  float_group = group['Float'] || group.new_group('Float')
  ai_group = float_group['AICompanion'] || float_group.new_group('AICompanion', 'AICompanion')
  file_ref = ai_group.files.find { |f| f.path == 'AIAvatarWindow.swift' } || ai_group.new_file('AIAvatarWindow.swift')
  unless target.source_build_phase.files_references.include?(file_ref)
    target.add_file_references([file_ref])
  end
  project.save
  puts "Added AIAvatarWindow.swift successfully."
else
  puts "GeoAdvanture group not found."
end
