EnvelopeCommunity.find_or_create_by(name: 'learning_registry',
                                    backup_item: 'learning-registry-test')

EnvelopeCommunity.find_or_create_by(name: 'ce_registry',
                                    backup_item: 'ce-registry-test',
                                    default: true)

admin = Admin.find_or_create_by(name: 'ce_admin')
organization = Organization.find_or_create_by(name: 'Generic Organization', admin: admin)
publisher = Publisher.find_or_create_by(name: 'ce', admin: admin, super_publisher: true)
OrganizationPublisher.find_or_create_by(organization: organization, publisher: publisher)
User.find_or_create_by(email: 'user@ce.org', publisher: publisher, admin: admin)
