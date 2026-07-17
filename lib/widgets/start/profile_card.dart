import 'package:flutter/material.dart';

import '../../models/profile_info.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.profile, super.key});
  final ProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name.isEmpty ? 'Unbekannt' : profile.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (profile.affiliation.isNotEmpty)
                        Text(
                          profile.affiliation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (profile.matriculationNumber.isNotEmpty) ...[
              const Divider(height: 24),
              InfoRow('Matrikelnummer', profile.matriculationNumber),
            ],
            if (profile.personKey.isNotEmpty)
              InfoRow('Personenkennzeichen', profile.personKey),
            if (profile.contacts.isNotEmpty) ...[
              const Divider(height: 24),
              ...profile.contacts.map((c) => ContactRow(contact: c)),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  const ContactRow({required this.contact, super.key});
  final ProfileContact contact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            contact.type == 'phone' ? Icons.phone_outlined : Icons.mail_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              contact.value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (contact.isPrimary)
            Icon(
              Icons.star,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
