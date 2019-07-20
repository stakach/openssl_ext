require "../src/openssl_ext"

root_key = OpenSSL::RSA.new(2048)
root_ca = OpenSSL::X509::Certificate.new

name = OpenSSL::X509::Name.new
name.add_entry "CN", "Crystal Extra"
name.add_entry "OU", "Root CA"
name.add_entry "O", "Crystal Shards"
name.add_entry "C", "US"

root_ca.serial = 1
root_ca.subject = name
root_ca.issuer = root_ca.subject
root_ca.public_key = root_key.public_key
root_ca.not_before = OpenSSL::ASN1::Time.days_from_now(0)
root_ca.not_after = OpenSSL::ASN1::Time.days_from_now(365 * 10)

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = root_ca
ef.issuer_certificate = root_ca

root_ca.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
root_ca.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
root_ca.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))
root_ca.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always", false))

root_ca.sign(root_key, OpenSSL::Digest::SHA256.new)

File.write "ca_cert.pem", root_ca.to_pem
File.write "ca_key.pem", root_key.to_pem

ca_key = OpenSSL::RSA.new(File.read("ca_key.pem"))
ca_cert = OpenSSL::X509::Certificate.new(File.read("ca_cert.pem"))

server_key = OpenSSL::EC.new(384)
server_cert = OpenSSL::X509::Certificate.new

server_cert.serial = 2
server_cert.subject = OpenSSL::X509::Name.parse "CN=*.crystal-lang.org"
server_cert.issuer = ca_cert.subject
server_cert.public_key = server_key.public_key
server_cert.not_before = OpenSSL::ASN1::Time.days_from_now(0)
server_cert.not_after = OpenSSL::ASN1::Time.days_from_now(365)

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = server_cert
ef.issuer_certificate = root_ca
ext = ef.create_extension("subjectAltName", "DNS:crystal-lang.org,DNS:*.crystal-lang.org", false)

server_cert.add_extension(ext)
server_cert.sign(server_key, OpenSSL::Digest::SHA384.new)

File.write "server_cert.pem", server_cert.to_pem
File.write "server_key.pem", server_key.to_pem
