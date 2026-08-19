<?php

declare(strict_types=1);

return [
    'version' => 1,
    'availability' => 'required_policy',
    'routes' => [
        [
            'route_id' => 'privacy_policy',
            'ingress_requirement' => 'public_shell_required',
            'public_shell_route_id' => 'privacy_policy',
            'roles' => ['continuation'],
            'query_keys' => [],
        ],
        [
            'route_id' => 'project_landing',
            'ingress_requirement' => 'public_shell_required',
            'public_shell_route_id' => 'project_landing',
            'roles' => ['continuation'],
            'query_keys' => [],
        ],
        [
            'route_id' => 'project_profile',
            'ingress_requirement' => 'public_shell_required',
            'public_shell_route_id' => 'project_profile',
            'roles' => ['continuation'],
            'query_keys' => [],
        ],
        [
            'route_id' => 'project_event',
            'ingress_requirement' => 'public_shell_required',
            'public_shell_route_id' => 'project_event',
            'roles' => ['continuation'],
            'query_keys' => [],
        ],
    ],
];
