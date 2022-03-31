Name: cookbook-barnyard2
Version: %{__version}
Release: %{__release}%{?dist}.1
BuildArch: noarch
Summary: cookbook to deploy barnyard2 in redborder environments

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-example
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/barnyard2
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/barnyard2
chmod -R 0755 %{buildroot}/var/chef/cookbooks/barnyard2
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/barnyard2/README.md

%pre

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload barnyard2'
  ;;
esac

%files
%defattr(0755,root,root)
/var/chef/cookbooks/barnyard2
%defattr(0644,root,root)
/var/chef/cookbooks/barnyard2/README.md


%doc

%changelog
* Fri Jan 07 2022 David Vanhoucke <dvanhoucke@redborder.com> - 0.0.5-1
- change register to consul
* Wed Oct 06 2021 Javier Rodriguez <javiercrg@redborder.com> - 0.0.2-1
- Added creation template directory

* Mon Jan 16 2017 Alberto Rodríguez <arodriguez@redborder.com> - 0.0.1-1
- first spec version
