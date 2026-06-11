/**
 * KaJota Concierge — Rapid Agent submission mobile entry point.
 *
 * Single-screen Expo app: the Concierge chat. No auth gate, no other
 * screens, no Privy / Mesh / Coach Agent v2 surfaces — those live in
 * the broader KaJota product and aren't part of this submission.
 *
 * The chat screen calls the deployed agent at
 * `kajota-concierge-agent.onrender.com` by default. Override the URL
 * via `app.json` -> `extra.conciergeAgentBaseUrl` to point at a local
 * `python -m kajota_concierge.server` instance.
 */
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { StatusBar } from 'expo-status-bar';

import { colors } from '@/constants/colors';
import ConciergeScreen from '@/screens/ConciergeScreen';
import type { RootStackParamList } from '@/types';

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <NavigationContainer>
      <StatusBar style="dark" />
      <Stack.Navigator
        initialRouteName="Concierge"
        screenOptions={{
          headerShown: true,
          title: 'KaJota Concierge',
          headerTintColor: colors.text,
          contentStyle: { backgroundColor: colors.pageBackground },
        }}
      >
        <Stack.Screen component={ConciergeScreen} name="Concierge" />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
