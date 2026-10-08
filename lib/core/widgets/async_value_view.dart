import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/menu_repository.dart';

/// Shows loading, error (with retry) or data for an [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.loadingLabel = 'Loading',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final String loadingLabel;

  @override
  Widget build(BuildContext context) {
    // Keep showing data we already have while a refresh is in flight.
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) {
      return ErrorView(message: friendlyError(value.error!), onRetry: onRetry);
    }
    return LoadingView(label: loadingLabel);
  }
}

/// Turns any error into a message that is safe and useful to show.
String friendlyError(Object error) {
  if (error is RepositoryException) return error.message;
  return 'Something went wrong. Please try again.';
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: label,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(minimumSize: const Size(180, 52)),
            ),
          ],
        ),
      ),
    );
  }
}
