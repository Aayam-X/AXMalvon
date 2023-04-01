import { initializeApp } from 'firebase/app';
import {
    getAuth,
    signOut,
    createUserWithEmailAndPassword,
    signInWithEmailAndPassword
} from 'firebase/auth';
import {
    getFirestore,
    doc,
    getDoc,
    setDoc
} from "firebase/firestore";

const firebaseApp = initializeApp({
apiKey: "AIzaSyBAbUKFAcLHmnN853MnhPoe9DgOh5Dc0E8",
authDomain: "axmalvon.firebaseapp.com",
projectId: "axmalvon",
storageBucket: "axmalvon.appspot.com",
messagingSenderId: "786960340314",
appId: "1:786960340314:web:56ac7e25a1e7bc166e8f63"
});
const auth = getAuth(firebaseApp);
const db = getFirestore(firebaseApp);

// Parse url parameters
const urlParams = new URLSearchParams(window.location.search);

// Logout if necessary
if (urlParams.has('logout')) {
    await signOut(auth);
}

// Function to create a database for a user
async function createDatabase(name, email) {
    await setDoc(doc(db, 'users', auth.currentUser.uid), {
        name,
        email,
    hasPaid: false,
    });
}

// Sign up if necessary
if (urlParams.has('name')) {
    const name = urlParams.get('name');
    const email = urlParams.get('email');
    const password = urlParams.get('password');
    
    try {
        await createUserWithEmailAndPassword(auth, email, password);
        createDatabase(name, email);
        document.getElementById('status').innerHTML = 'success';
    } catch (error) {
        console.error(`Error signing up: ${error}`);
        document.getElementById('status').innerHTML = `failed: ${error}`;
    }
}

// Sign in if necessary
if (urlParams.has('email') && urlParams.has('password')) {
    const email = urlParams.get('email');
    const password = urlParams.get('password');
    
    try {
        await signInWithEmailAndPassword(auth, email, password)
        .then(async () => {
            // Read database to see if user has it or not
            const docRef = doc(db, 'users', auth.currentUser.uid);
            const docSnap = await getDoc(docRef);
            if (docSnap.exists()) {
                let hasPaid = docSnap.data().hasPaid;
                document.getElementById('status').innerHTML = `success: ${hasPaid}`;
            } else {
                // Delete the user
                auth.currentUser.delete();
            }
        })
    } catch (error) {
        console.error(`Error signing in: ${error}`);
        document.getElementById('status').innerHTML = `failed: ${error}`;
    }
}
