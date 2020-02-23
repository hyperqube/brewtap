class PostgresqlHq < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  url "https://ftp.postgresql.org/pub/source/v12.2/postgresql-12.2.tar.bz2"
  sha256 "ad1dcc4c4fc500786b745635a9e1eba950195ce20b8913f50345bb7d5369b5de"
  revision 1
  head "https://git.postgresql.org/git/postgresql.git"


#  bottle do
#    sha256 "857634536138eeec0ea34cdbf42fb6ce15a7f3f824394f7feed6cc49e1e0963c" => :mojave
#    sha256 "333601920c1dd2e3bc3f06684697ac3ef0b15ac4a188817a18d0c8cfb4b032a1" => :high_sierra
#    sha256 "10450729ca8c5573dfc8a87018c5cba133045783fb9a6ccbeb3b2c2e016e444f" => :sierra
#  end

  depends_on "pkg-config" => :build
  depends_on "icu4c"
  depends_on "openssl"
  depends_on "readline"
  conflicts_with  "postgresql",
    :because => "postgresql  ,postgresql-hqinstall the same binaries."

  def install
    # avoid adding the SDK library directory to the linker search path

    libs = %w[openssl llvm readline ]

    libs.each{ |i| 
      ENV.prepend "LDFLAGS", "-L#{Formula[i].opt_lib}"
      ENV.prepend "CPPFLAGS", "-L#{Formula[i].opt_include}"

    }
    ENV["XML2_CONFIG"] = "xml2-config --exec-prefix=/usr"
    ENV.append 'PATH', ":/usr/local/Cellar/llvm/9.0.0/bin"
    #ENV.prepend "LDFLAGS", " -L#{Formula["openssl"].opt_lib} -L#{Formula["readline"].opt_lib}   -L/usr/local/Cellar/llvm/9.0.0/lib -Wl,-rpath,usr/local/Cellar/llvm/9.0.0/lib"
    #ENV.prepend "CPPFLAGS", " -I#{Formula["openssl"].opt_include} -I#{Formula["readline"].opt_include}  -I/usr/local/Cellar/llvm/9.0.0/include"
    ENV['LLVM_CONFIG']='/usr/local/Cellar/llvm/9.0.0/bin/llvm-config'
    args = %W[
      --disable-debug
      --prefix=#{prefix}
      --datadir=#{HOMEBREW_PREFIX}/share/postgresql
      --libdir=#{HOMEBREW_PREFIX}/lib
      --sysconfdir=#{etc}
      --docdir=#{doc}
      --enable-thread-safety
      --with-bonjour
      --with-gssapi
      --with-icu
      --with-libxml
      --with-libxslt
      --with-openssl
      --with-ldap
      --with-pam
      --with-uuid=e2fs
      --with-llvm
    ]
     # 

    
    system "./configure", *args
    system "make"
    system "make", "install-world", "datadir=#{pkgshare}",
                                    "libdir=#{lib}",
                                    "pkglibdir=#{lib}/postgresql"
  end

  def post_install
    (var/"log").mkpath
    (var/"postgres").mkpath
    unless File.exist? "#{var}/postgres/PG_VERSION"
      system "#{bin}/initdb", "--locale=C", "-E", "UTF-8", "#{var}/postgres"
    end
  end

  def caveats; <<~EOS
    To migrate existing data from a previous major version of PostgreSQL run:
      brew postgresql-upgrade-database
  EOS
  end

  plist_options :manual => "pg_ctl -D #{HOMEBREW_PREFIX}/var/postgres start"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeepAlive</key>
      <true/>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_bin}/postgres</string>
        <string>-D</string>
        <string>#{var}/postgres</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>WorkingDirectory</key>
      <string>#{HOMEBREW_PREFIX}</string>
      <key>StandardOutPath</key>
      <string>#{var}/log/postgres.log</string>
      <key>StandardErrorPath</key>
      <string>#{var}/log/postgres.log</string>
    </dict>
    </plist>
  EOS
  end

  test do
    system "#{bin}/initdb", testpath/"test"
    assert_equal "#{HOMEBREW_PREFIX}/share/postgresql", shell_output("#{bin}/pg_config --sharedir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib", shell_output("#{bin}/pg_config --libdir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib/postgresql", shell_output("#{bin}/pg_config --pkglibdir").chomp
  end
end
