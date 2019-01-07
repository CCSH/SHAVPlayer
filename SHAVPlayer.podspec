Pod::Spec.new do |s|
    s.name         = "SHAVPlayer"
    s.version      = "1.0.0"
    s.summary      = "视频播放器"
    s.license      = "MIT"
    s.authors      = { "CSH" => "624089195@qq.com" }
    s.platform     = :ios, "8.0"
    s.requires_arc = true
    s.homepage     = "https://github.com/CCSH/SHAVPlayer"
    s.source       = { :git => "https://github.com/CCSH/SHAVPlayer.git", :tag => s.version }
    s.source_files = "SHAVPlayer/*.{h,m}"
end
