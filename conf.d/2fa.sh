#!/usr/bin/env bash

echo -e "\033[1mInstalling markshust/magento2-module-disabletwofactorauth... \033[0m"
docker-compose exec -T phpfpm composer require markshust/magento2-module-disabletwofactorauth
docker-compose exec -T phpfpm bin/magento module:enable MarkShust_DisableTwoFactorAuth

echo -e "\033[1mDisabling 2FA... \033[0m"
docker-compose exec -T phpfpm bin/magento config:set twofactorauth/general/enable 0


# No need to run setup:upgrade, bin/setup-magento runs setup:upgrade after calling the user scripts