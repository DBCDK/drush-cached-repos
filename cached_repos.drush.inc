<?php
/**
 * @file
 * Utilities for Drush. Release build scripts.
 *
 * © 2012 DBC A/S and TING.Community
 *
 * Version: 1.0.0.
 */

/**
 * Implements hook_drush_help_alter().
 *
 * In Drush 5 we must define the options.
 */

define('REPO_TRANSLATE', "s/:\/\//-/; y/@:/-\//");

function cached_repos_drush_help_alter(&$command) {
  if ($command['command'] == 'make' || $command['command'] == 'ding-deploy') {
    $command['options']['cached-repos-baseurl'] = 'Base url or path of repos';
    $command['options']['cached-repos-translate'] = 'Translation of characters not fit for urls (default: ' . REPO_TRANSLATE . ')';
  }
}

/**
 * Implements hook_drush_make_validate_info().
 *
 * This is the Drush 4.5 variant of the validate makefile hook.
 */
function cached_repos_drush_make_validate_info($info) {
  return _cached_repos_make_validate_info($info);
}

/**
 * Implements hook_make_validate_info().
 *
 * This is the Drush 5 variant of the validate makefile hook.
 */
function cached_repos_make_validate_info($info) {
  return _cached_repos_make_validate_info($info);
}

/**
 * Internal version of the validate makefile.
 */
function _cached_repos_make_validate_info($info) {
  $baseurl = drush_get_option('cached-repos-baseurl', FALSE);
  $translate = drush_get_option('cached-repos-translate', REPO_TRANSLATE);

  if (! $baseurl) {
    return $info;
  }

  // @todo more than projects
  foreach ($info['projects'] as $name => &$spec) {
    // Only consider git repositories. @todo more than git repositories
    if (!empty($spec['download']['type']) && $spec['download']['type'] == 'git') {
      $oldurl = $spec['download']['url'];
      drush_shell_exec('echo %s | sed -e %s', $spec['download']['url'], $translate);
      $output = drush_shell_exec_output();
      $spec['download']['url'] = $baseurl . '/' . $output[0];

      drush_log(dt('Using @newurl instead of @oldurl.',
          array(
            '@oldurl' => $oldurl,
            '@newurl' => $spec['download']['url'],
          )), 'ok');
    }
  }

  return $info;
}
