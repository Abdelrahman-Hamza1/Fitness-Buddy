import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

import '../helpers/property.dart';

const _proposal = '0199e3c2-5b1a-7c3d-8e4f-0123456789ab';
const _changeSet = '0199e3c2-5b1b-7000-8000-000000000001';

void main() {
  group('Origin:', () {
    test(
      'Origin text round trip (direct, proposal:<id>, undo:<id>, system)',
      () {
        final cases = {
          Origin.direct: 'direct',
          Origin.system: 'system',
          Origin.proposal(_proposal): 'proposal:$_proposal',
          Origin.undo(_changeSet): 'undo:$_changeSet',
        };
        for (final MapEntry(key: origin, value: text) in cases.entries) {
          expect(origin.toText(), text);
          expect('$origin', text);
          expect(Origin.parse(text), origin);
          expect(Origin.tryParse(text), origin);
        }
        expect(Origin.parse('direct'), same(Origin.direct));
        expect(Origin.parse('system'), same(Origin.system));
      },
    );

    Glados(any.uuid, propertyRuns).test(
      'Origin text round trip for any proposal and change set ID',
      (id) {
        for (final origin in [Origin.proposal(id), Origin.undo(id)]) {
          expect(Origin.parse(origin.toText()), origin);
        }
      },
    );

    test('invalid Origin text is rejected', () {
      const invalid = [
        '',
        'Direct',
        'direct ',
        'user',
        'proposal',
        'proposal:',
        'proposal:not-a-uuid',
        'proposal:${'0199E3C2-5B1A-7C3D-8E4F-0123456789AB'}',
        'undo:$_changeSet:x',
        'redo:$_changeSet',
        ':$_changeSet',
        'system:$_changeSet',
      ];
      for (final text in invalid) {
        expect(Origin.tryParse(text), isNull, reason: text);
        expect(() => Origin.parse(text), throwsFormatException, reason: text);
      }
    });

    test('proposal and undo origins need a lowercase canonical UUID', () {
      expect(() => Origin.proposal('x'), throwsArgumentError);
      expect(() => Origin.undo(_changeSet.toUpperCase()), throwsArgumentError);
    });

    test('Origin equality by kind and ID', () {
      expect(Origin.proposal(_proposal), Origin.proposal(_proposal));
      expect(
        Origin.proposal(_proposal).hashCode,
        Origin.proposal(_proposal).hashCode,
      );
      expect(Origin.undo(_changeSet), Origin.undo(_changeSet));
      expect(
        Origin.undo(_changeSet).hashCode,
        Origin.undo(_changeSet).hashCode,
      );
      expect(Origin.proposal(_proposal), isNot(Origin.undo(_proposal)));
      expect(Origin.proposal(_proposal), isNot(Origin.proposal(_changeSet)));
      expect(Origin.direct, isNot(Origin.system));
    });
  });

  group('ChangeSet:', () {
    final put = SettingsOp.put('units.system', '"metric"');

    test('ChangeSet rejects empty and > 500 ops', () {
      expect(
        () => ChangeSet(const [], origin: Origin.direct),
        throwsArgumentError,
      );
      expect(
        () => ChangeSet(
          List.filled(ChangeSet.maxOps + 1, put),
          origin: Origin.direct,
        ),
        throwsArgumentError,
      );
      expect(ChangeSet([put], origin: Origin.direct).ops, [put]);
      expect(
        ChangeSet(
          List.filled(ChangeSet.maxOps, put),
          origin: Origin.direct,
        ).ops,
        hasLength(500),
      );
    });

    test('ChangeSet keeps the op order and its ops are unmodifiable', () {
      final source = [put, SettingsOp.reset('a'), SettingsOp.reset('b')];
      final set = ChangeSet(source, origin: Origin.system);
      source.clear();
      expect(set.ops, [put, SettingsOp.reset('a'), SettingsOp.reset('b')]);
      expect(set.origin, Origin.system);
      expect(() => set.ops.add(put), throwsUnsupportedError);
      expect('$set', 'ChangeSet(system, 3 ops)');
    });

    test('ChangeSet equality by origin and ops in order', () {
      final a = SettingsOp.reset('a');
      final b = SettingsOp.reset('b');
      final set = ChangeSet([a, b], origin: Origin.direct);
      expect(set, ChangeSet([a, b], origin: Origin.direct));
      expect(set.hashCode, ChangeSet([a, b], origin: Origin.direct).hashCode);
      expect(set, isNot(ChangeSet([b, a], origin: Origin.direct)));
      expect(set, isNot(ChangeSet([a], origin: Origin.direct)));
      expect(set, isNot(ChangeSet([a, b], origin: Origin.system)));
    });
  });

  group('ChangeSetApplied:', () {
    test('ChangeSetApplied carries the change set, origin and entities', () {
      final event = ChangeSetApplied(
        changeSetId: _changeSet,
        origin: Origin.direct,
        entities: ['setting', 'setting'],
      );
      expect(event, isA<DomainEvent>());
      expect(event.changeSetId, _changeSet);
      expect(event.origin, Origin.direct);
      expect(event.entities, {'setting'});
      expect(() => event.entities.add('x'), throwsUnsupportedError);
      expect('$event', 'ChangeSetApplied($_changeSet, direct, {setting})');
    });

    test('ChangeSetApplied equality ignores the entity order', () {
      ChangeSetApplied applied(List<String> entities, {Origin? origin}) =>
          ChangeSetApplied(
            changeSetId: _changeSet,
            origin: origin ?? Origin.direct,
            entities: entities,
          );
      expect(applied(['a', 'b']), applied(['b', 'a']));
      expect(applied(['a', 'b']).hashCode, applied(['b', 'a']).hashCode);
      expect(applied(['a']), isNot(applied(['a', 'b'])));
      expect(applied(['a']), isNot(applied(['b'])));
      expect(applied(['a']), isNot(applied(['a'], origin: Origin.system)));
      expect(
        applied(['a']),
        isNot(
          ChangeSetApplied(
            changeSetId: _proposal,
            origin: Origin.direct,
            entities: const ['a'],
          ),
        ),
      );
    });
  });
}
