import {
  requireNativeComponent,
  View,
  NativeModules,
  Platform,
  DeviceEventEmitter
} from 'react-native';

import React, {
  Component,
  PropTypes
} from 'react';

import _MapTypes from './js/MapTypes';
import _MapView from './js/MapView';
import _Geolocation from './js/Geolocation';

export const MapTypes = _MapTypes;
export const MapView = _MapView;
export const Geolocation = _Geolocation;
