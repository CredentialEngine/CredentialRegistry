EnvelopeCommunity.create([{ name: 'learning_registry',
                            backup_item: 'learning-registry-test' },
                          { name: 'ce_registry',
                            backup_item: 'ce-registry-test',
                            default: true }])

admin = Admin.create(name: 'ce_admin')
publisher = Publisher.create(name: 'ce_admin', admin: admin)
User.create(email: 'user@ce.org', publisher: publisher)
