<?php

declare(strict_types=1);

return [
    'extensions' => [
        [
            'extension_id' => 'custom_public_metadata',
            'service_container_id' => 'project.public_shell.custom_public_metadata_extension',
            'supported_shapes' => ['exact'],
        ],
    ],
    'routes' => [
        [
            'route_id' => 'project_landing',
            'path' => '/project-entry',
            'shape' => 'exact',
            'semantic' => 'shell',
        ],
        [
            'route_id' => 'project_profile',
            'path' => '/project-profiles/',
            'shape' => 'one_segment',
            'semantic' => 'account_profile_metadata',
        ],
        [
            'route_id' => 'project_event',
            'path' => '/project-events/',
            'shape' => 'one_segment',
            'semantic' => 'event_metadata',
        ],
        [
            'route_id' => 'project_custom_metadata',
            'path' => '/project-campaign',
            'shape' => 'exact',
            'semantic' => 'custom_public_metadata',
        ],
    ],
];
