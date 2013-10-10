bash "add erlang source to apt sources" do
  code <<-EOH
    echo 'deb http://packages.erlang-solutions.com/debian precise contrib' >> /etc/apt/sources.list
    wget -O - http://packages.erlang-solutions.com/debian/erlang_solutions.asc | apt-key add -
  EOH
  not_if "grep asdfsdf /etc/apt/sources.list"
end

bash "update apt" do
  code "apt-get update"
end

package "esl-erlang" do
  action :install
end



package "git-core" do
  action :install
end

bash "install rebar" do
  code <<-EOH
    cd ~/
    git clone git://github.com/rebar/rebar.git
    cd rebar/
    ./bootstrap
    cp rebar /usr/bin/
  EOH
end



group 'ejabberd'
user 'ejabberd' do
  group 'ejabberd'
end

[
  "build-essential",
  "libssl-dev",
  "libexpat1-dev",
  "zlib1g-dev",
].each do |pkg|
  package pkg do
    action :install
  end
end

bash "compile ejabberd" do
  code <<-EOH
    cd ~/
    git clone https://github.com/processone/ejabberd.git ejabberd
    cd ejabberd
    git checkout -b 2.1.x origin/2.1.x
    cd src
    ./configure --enable-odbc --prefix=/usr --enable-user=ejabberd --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib
    make install
  EOH
end




bash "install ejabberd mysql" do
  code <<-EOH
    cd ~/
    git clone https://github.com/processone/mysql
    cd mysql/
    git checkout -b pre_p1 42e8d4c2c38e32358235fe42136c6433fa5aa83e
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
  EOH
end




bash "install mod_admin_extra" do
  code <<-EOH
    cd ~
    git clone git://github.com/processone/ejabberd-contrib.git
    cd ejabberd-contrib
    git checkout 2.1.x
    cd mod_admin_extra
    ./build.sh
    cp ebin/* /usr/lib/ejabberd/ebin
  EOH
end




template "/etc/init.d/ejabberd" do
  owner 'root'
  group 'root'
  mode 0755
  source "init.d/ejabberd.erb"
end

template "/etc/ejabberd/ejabberd.cfg" do
  source "ejabberd.cfg.erb"
  owner "ejabberd"
  variables({
    :jabber_domain      => node[:jabber_domain],
    :mysql_hostname     => node[:mysql_hostname],
    :mysql_databasename => node[:mysql_databasename],
    :mysql_username     => node[:mysql_username],
    :mysql_password     => node[:mysql_password]
  })
end

template "/etc/ejabberd/ejabberdctl.cfg" do
  source "ejabberdctl.cfg.erb"
  owner "ejabberd"
end

template "/etc/ejabberd/inetrc" do
  source "inetrc.erb"
  owner "ejabberd"
end

package "nginx"

service "nginx" do
  action :start
end

cookbook_file "ejabberd.example.pem" do
  path "/etc/ejabberd/ejabberd.pem"
  owner "ejabberd"
  group "ejabberd"
  mode "600"
  action :create
end


service "ejabberd" do
  action :enable
  supports :restart => true
end
