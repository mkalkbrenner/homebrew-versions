require 'formula'

class Ruby19 < Requirement
  fatal true
  default_formula "ruby"

  satisfy :build_env => false do
    next unless which "ruby"
    version = /\d\.\d/.match `ruby --version 2>&1`
    next unless version
    Version.new(version.to_s) >= Version.new("1.9")
  end

  def modify_build_environment
    ruby = which "ruby"
    return unless ruby
    ENV.prepend_path "PATH", ruby.dirname
  end

  def message; <<-EOS.undent
    The mkvtoolnix buildsystem needs Ruby >=1.9
    EOS
  end
end

class Mkvtoolnix58 < Formula
  homepage 'http://www.bunkus.org/videotools/mkvtoolnix/'
  url 'http://www.bunkus.org/videotools/mkvtoolnix/sources/mkvtoolnix-5.8.0.tar.bz2'
  sha1 '5077bcc6403acc18a867a309861e86b593227bb9'

  depends_on 'pkg-config' => :build
  depends_on Ruby19
  depends_on 'libvorbis'
  depends_on 'flac' => :optional
  depends_on 'lzo' => :optional
  # On Mavericks, the bottle (without c++11) can be used
  # because mkvtoolnix is linked against libc++ by default
  if MacOS.version >= 10.9
    depends_on 'boost'
    depends_on 'libmatroska'
    depends_on 'libebml'
  else
    depends_on 'boost' => 'c++11'
    depends_on 'libmatroska' => 'c++11'
    depends_on 'libebml' => 'c++11'
  end

  needs :cxx11

  def install
    ENV.cxx11

    ENV['ZLIB_CFLAGS'] = '-I/usr/include'
    ENV['ZLIB_LIBS'] = '-L/usr/lib -lz'

    boost = Formula["boost"].opt_prefix

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--disable-gui",
                          "--disable-wxwidgets",
                          "--without-curl",
                          "--with-boost=#{boost}"
    system "./drake", "-j#{ENV.make_jobs}"
    system "./drake install"
  end

  test do
    mkv_path = testpath/"Great.Movie.mkv"
    sub_path = testpath/"subtitles.srt"
    sub_path.write <<-EOS.undent
      1
      00:00:10,500 --> 00:00:13,000
      Homebrew
    EOS

    system "#{bin}/mkvmerge", "-o", mkv_path, sub_path
    system "#{bin}/mkvinfo", mkv_path
    system "#{bin}/mkvextract", "tracks", mkv_path, "0:#{sub_path}"
  end
end
