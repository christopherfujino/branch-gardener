import 'dart:convert';
import 'dart:io' as io;

import 'src/utils.dart';

Future<void> main() async {
  final branchNames = (await run('git', <String>['branch', '--list', '--format=%(refname)']))
      .trim()
      .split('\n')
      .map<String>((String line) => line.replaceFirst(r'refs/heads/', ''))
      .toList();

  int longestBranchName = 0;
  final branchFutures = branchNames.map<Future<Branch?>>((String name) async {
    name = name.trim();
    if (name.isEmpty) {
      return null;
    }
    final int branchLength = name.length;
    if (branchLength > longestBranchName) {
      longestBranchName = branchLength;
    }
    final commitDate = await run(
      'git',
      // show only date
      <String>['show', '--no-patch', '--format=%ci', name],
    );
    final commitAuthor = await run(
      'git',
      <String>['show', '--no-patch', '--format=%cn', name],
    );
    final date = DateTime.parse(commitDate);
    return Branch(
      name: name,
      date: date,
      author: commitAuthor,
    );
  });
  final branches = (await Future.wait(branchFutures)).whereType<Branch>().toList()..sort();
  if (branches.isEmpty) {
    throw Exception('No branches found');
  }
  final buffer = StringBuffer();
  for (final branch in branches) {
    buffer.write(branch.name.padRight(longestBranchName));
    buffer.write(' - ');
    buffer.write(branch.date.year);
    buffer.write('-');
    buffer.write(branch.date.month.toString().padLeft(2, '0'));
    buffer.write('-');
    buffer.write(branch.date.day.toString().padLeft(2, '0'));
    buffer.write(' - ');
    buffer.write(branch.author);
    buffer.write('\n');
  }

  final process = await io.Process.start(
    'fzf',
    const <String>['--multi'],
  );
  process.stdin.write(buffer);
  final linesFuture = process.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .toList();
  process.stdin.addStream(io.stdin);
  io.stderr.addStream(process.stderr);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('fzf exited with $exitCode\n${(await linesFuture).join('\n')}');
  }
  final lines = await linesFuture;
  lines.forEach(_deleteBranch);
}

Future<void> _deleteBranch(String name) async {
  name = name.trim();
  if (name.isEmpty) {
    return;
  }

  print('Force deleting branch $name...');
  run(
    'git',
    <String>['branch', '-d', '--force', name],
  );
}

class Branch implements Comparable<Branch> {
  const Branch({
    required this.date,
    required this.author,
    required this.name,
  });

  final DateTime date;
  final String author;
  final String name;

  int compareTo(Branch other) => date.compareTo(other.date);
}

