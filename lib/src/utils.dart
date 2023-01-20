import 'dart:io' as io;

Future<String> run(String executable, List<String> args) async {
  final result = await io.Process.run(
    executable,
    args,
  );

  if (result.exitCode != 0) {
    throw Exception('Command `$executable ${args.join(' ')}` failed:\n${result.stderr}');
  }

  return (result.stdout as String).trim();
}
