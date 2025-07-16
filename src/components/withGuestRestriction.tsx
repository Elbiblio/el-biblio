import React, { useState } from 'react';
import { useGuestRestrictions } from '@/hooks/useGuestRestrictions';
import GuestRestrictionModal from './GuestRestrictionModal';

interface WithGuestRestrictionProps {
  feature: string;
  children: React.ReactNode;
  onRestricted?: () => void;
}

export const withGuestRestriction = <P extends object>(
  WrappedComponent: React.ComponentType<P>,
  feature: string
) => {
  return (props: P) => {
    const [showRestrictionModal, setShowRestrictionModal] = useState(false);
    const { restrictions, getRestrictionMessage } = useGuestRestrictions();

    const handleRestrictedAction = () => {
      const restrictionMessage = getRestrictionMessage(feature as keyof typeof restrictions);
      if (restrictionMessage) {
        setShowRestrictionModal(true);
        return false;
      }
      return true;
    };

    return (
      <>
        <WrappedComponent
          {...props}
          isActionAllowed={handleRestrictedAction}
          showRestrictionModal={() => setShowRestrictionModal(true)}
        />
        <GuestRestrictionModal
          visible={showRestrictionModal}
          onClose={() => setShowRestrictionModal(false)}
          feature={feature}
        />
      </>
    );
  };
};

export const GuestRestrictionWrapper: React.FC<WithGuestRestrictionProps> = ({
  feature,
  children,
  onRestricted,
}) => {
  const [showRestrictionModal, setShowRestrictionModal] = useState(false);
  const { restrictions, getRestrictionMessage } = useGuestRestrictions();

  const handleRestrictedAction = () => {
    const restrictionMessage = getRestrictionMessage(feature as keyof typeof restrictions);
    if (restrictionMessage) {
      setShowRestrictionModal(true);
      onRestricted?.();
      return false;
    }
    return true;
  };

  return (
    <>
      {React.cloneElement(children as React.ReactElement, {
        isActionAllowed: handleRestrictedAction,
        showRestrictionModal: () => setShowRestrictionModal(true),
      })}
      <GuestRestrictionModal
        visible={showRestrictionModal}
        onClose={() => setShowRestrictionModal(false)}
        feature={feature}
      />
    </>
  );
}; 