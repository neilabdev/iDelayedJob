Pod::Spec.new do |s|
  s.name             = "iDelayedJob"
  s.version          = "1.0.6"
  s.summary          = "A Job scheduler allowing transparent performance and retrying of misc task until successful or exhausted, even across application restarts."
  s.description      = <<-DESC
                        iDelayedJob is a Job scheduler allowing transparent performance and retrying of
                        task until successful or exhausted  even across application restart, and is modeled and
                        inspired by the equivalent rails plugin of similar name.
                       DESC
  s.homepage         = "https://github.com/valerius/iDelayedJob"
  s.license          = 'MIT'
  s.author           = { "James Whitfield" => "valerius@neilab.com" }
  s.source           = { :git => "https://github.com/valerius/iDelayedJob.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'iDelayedJob' => ['Pod/Assets/*.png']
  }
  s.dependency 'VinylRecord'
  s.dependency 'JSONKit-NoWarning', '~> 1.2'
  s.dependency 'Reachability', '~> 3.2'
  s.dependency 'MSWeakTimer', '~> 1.1.0'
  # s.public_header_files = 'Pod/Classes/**/*.h'
end
