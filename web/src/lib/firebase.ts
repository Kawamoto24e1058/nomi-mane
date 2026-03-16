// Import the functions you need from the SDKs you need
// @ts-ignore
import { initializeApp } from "firebase/app";
// @ts-ignore
import { getAnalytics, isSupported } from "firebase/analytics";
// @ts-ignore
import { getFirestore } from "firebase/firestore";
// @ts-ignore
import { browser } from "$app/environment";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyDq-kJH6Z0doodQ2v-ixS1PKkqlW6AOwHI",
  authDomain: "nomimane.firebaseapp.com",
  projectId: "nomimane",
  storageBucket: "nomimane.firebasestorage.app",
  messagingSenderId: "1035978576239",
  appId: "1:1035978576239:web:1ac6ab40bb13aab10c189a",
  measurementId: "G-M3250XNQT4"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Services
export const db = getFirestore(app);

// Analytics is only supported in the browser
export let analytics: any = null;
if (browser) {
  isSupported().then((supported) => {
    if (supported) {
      analytics = getAnalytics(app);
    }
  });
}