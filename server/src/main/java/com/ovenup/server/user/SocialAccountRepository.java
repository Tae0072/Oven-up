package com.ovenup.server.user;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface SocialAccountRepository extends JpaRepository<SocialAccountEntity, Long> {

    Optional<SocialAccountEntity> findByProviderAndProviderUserId(String provider, String providerUserId);
}
