package com.bistri.api_demo;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.os.Bundle;
import android.text.InputFilter;
import android.util.Log;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.bistri.api2.wrapper.Conference;
import com.bistri.api2.wrapper.Conference.*;
import com.bistri.api2.wrapper.DataStream;
import com.bistri.api2.wrapper.MediaStream;
import com.bistri.api2.wrapper.PeerStream;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Timer;
import java.util.TimerTask;

import com.bistri.api_demo.R.*;


public class MainActivity extends Activity
    implements Conference.Listener, PeerStream.Handler {
    // Static Fields
    private static final String TAG = "MainActivity";
    private static final String DEFAULT_ROOM_NAME = "androidroom";
    private static final int PERMISSIONS_CAMERA_AND_MICROPHONE = 1;

    // Members
    private EditText roomEdit;
    private String roomName;
    private Button joinButton;
    private TextView status;
    private ImageView loaderSpinner;
    private MediaStreamLayout callLayout;
    private LinearLayout roomLayout;
    private boolean orientationLandscape;
    private boolean inCall;

    private boolean cameraFacingFront;
    private boolean permissions;
    private Conference conference;

    private View incrustView;

    /*
    *       Activity Management
    */

    @Override
    protected void onCreate (Bundle savedInstanceState)
    {
        super.onCreate( savedInstanceState );

        setContentView(layout.demo);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        inCall = false;
        conference = null;
        permissions = false;

        roomEdit = ( EditText )findViewById( id.room_name );
        joinButton = ( Button )findViewById( id.join_button );
        Button cam_switch = ( Button )findViewById( id.camera_switch_button );
        status = ( TextView )findViewById( id.status );
        loaderSpinner = ( ImageView )findViewById( id.loader_spinner );
        callLayout = ( MediaStreamLayout )findViewById( id.call_layout );
        roomEdit.setText(DEFAULT_ROOM_NAME);
        roomLayout = ( LinearLayout )findViewById( id.room_layout );
        orientationLandscape = (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE);
        if (orientationLandscape) {
            roomLayout.setOrientation(LinearLayout.HORIZONTAL);
        } else {
            roomLayout.setOrientation(LinearLayout.VERTICAL);
        }

        // Force to use only Alphanumeric characters.
        InputFilter filter = (source, start, end, dest, dstart, dend) -> {
            if ( !source.toString().matches("[a-zA-Z0-9_-]*") ) {
                return "";
            }
            return null;
        };

        roomEdit.setFilters(new InputFilter[]{filter});

        // Set keyboard action
        roomEdit.setOnEditorActionListener((v, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEND) {
                joinButton.performClick();
                return true;
            }
            return false;
        });

        // Set join button listener
        joinButton.setOnClickListener(view -> {

            roomName = roomEdit.getText().toString();

            if ( roomName.length() == 0 ) {
                Toast.makeText(this, string.create_input_error, Toast.LENGTH_SHORT).show();
                return;
            }

            if ( conference.getStatus() == Status.CONNECTED ) {
                conference.join(roomName);
                setInCall( true );
            } else {
                Log.w( TAG, "Cannot join room : not connected");
            }
        });

        // Set switch camera button listener
        cam_switch.setOnClickListener(view -> {
            cameraFacingFront = !cameraFacingFront;
            conference.setCameraFacing(cameraFacingFront);
        });


        final TextView test_text = findViewById(id.test_text);
        final int[] cpt = {0};

        if ( checkPermission() ) {
            // Permission are granted, so we can initialize conference
            initConference();
        }

    }

    private boolean checkPermission() {

        permissions = (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) &&
                (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED);

        if ( !permissions ) {
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO}, PERMISSIONS_CAMERA_AND_MICROPHONE);
        }

        return permissions;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if ( requestCode == PERMISSIONS_CAMERA_AND_MICROPHONE ) {

            if (grantResults.length > 0 && grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, string.permissions_error, Toast.LENGTH_LONG).show();
            }

            // Initialise conference in any case
            initConference();
        }
    }

    private boolean initConference()
    {
        onResumeConference();

        // Conference
        conference.setInfo( "38077edb", "4f304359baa6d0fd1f9106aaeb116f33" );

        conference.setVideoOption( VideoOption.MAX_WIDTH, 640 );
        conference.setVideoOption( VideoOption.MAX_HEIGHT, 480 );
        conference.setVideoOption( VideoOption.MAX_FRAME_RATE, 30 );

        conference.setLoudspeaker( true );
        conference.connect();

        return true;
    }

    void showLoaderSpinner( boolean visible )
    {
        int visibility = visible ? View.VISIBLE : View.GONE;

        if ( loaderSpinner.getVisibility() == visibility ) return; // Nothing to do

        if ( visible ) {
            // Initialize loading spinner animation
            Animation rotation = AnimationUtils.loadAnimation(this, anim.rotate);
            if (rotation != null) loaderSpinner.startAnimation(rotation);
        } else {
            loaderSpinner.clearAnimation();
        }
        loaderSpinner.setVisibility( visibility );
    }


    private void onResumeConference()
    {
        conference = Conference.getInstance( getApplicationContext() );
        conference.addListener( this );
        onConnectionEvent(conference.getStatus());
    }

    @Override
    protected void onResume()
    {
        super.onResume();

        onResumeConference();
    }

    @Override
    protected void onPause()
    {
        Log.d(TAG, "onPause");

        if (conference != null) {
            conference.removeListener( this );
        }

        super.onPause();
    }

    @Override
    protected void onDestroy()
    {
        Log.d(TAG, "onDestroy");

        if (conference!=null) {
            conference.disconnect();
        }
        super.onDestroy();
    }

    private void updateViewAccordingState(Status state) {

        if ( state == Status.DISCONNECTED ) {
            status.setText( string.disconnected );
        } else if ( ( state == Status.CONNECTING ) || ( state == Status.CONNECTING_SENDREQUEST ) ) {
            status.setText( string.connecting );
        } else if ( state == Status.CONNECTED ) {
            status.setText( string.connected );
        }

        boolean showLoader = ( state == Status.CONNECTING ) || ( state == Status.CONNECTING_SENDREQUEST );
        showLoaderSpinner( showLoader );

        roomEdit.setEnabled(state == Status.CONNECTED);
        joinButton.setEnabled(state == Status.CONNECTED);
    }

    private void setInCall( boolean inCall ){
        roomLayout.setVisibility( inCall ? View.GONE : View.VISIBLE );
        callLayout.setVisibility( inCall ? View.VISIBLE : View.GONE );
        if ( inCall ) {
            hideKeyboard();
        } else {
            callLayout.removeAllMediaStream();
        }
        this.inCall = inCall;
    }

    @Override
    public void onBackPressed() {
        Log.w(TAG, "onBackPressed");

        if (inCall) {
            conference.leave(roomName);
            return;
        }
        super.onBackPressed();
    }

    /*
    *       Listener implementation
    */

    @Override
    public void onConnectionEvent(Status state) {
        updateViewAccordingState(state);
    }

    @Override
    public void onError(ErrorEvent error) {
        if ( error == ErrorEvent.CONNECTION_ERROR ) {
            Toast.makeText(getApplicationContext(), "Connection error", Toast.LENGTH_LONG).show();
        }
    }

    @Override
    public void onRoomJoined(String roomName) {
        setInCall( true );
        conference.getMembers( roomName );
//        conference.setPresence(Presence.BUSY);
//        conference.getPresence(conference.getUserId()); // Test by querying my own presence
    }

    @Override
    public void onRoomQuitted(String roomName) {
        setInCall( false );
    }

    @Override
    public void onNewPeer( PeerStream peerStream ) {
        peerStream.setHandler( this );

        // Open dataChannel example
        if ( !peerStream.isLocal() ) {
            // Open dataChannel on remote peer stream
            peerStream.openDataChannel( "testDataChannelAndroid" );
        }
    }

    @Override
    public void onRemovedPeer(PeerStream peerStream) {
        if ( !peerStream.hasMedia() )
            return;

        MediaStream mediaStream = peerStream.getMedia();
        callLayout.removeMediaStream(mediaStream);
    }

    @Override
    public void onMediaStream(String peerId, MediaStream mediaStream) {
        callLayout.addMediaStream(mediaStream);
    }

    @Override
    public void onDataStream(String peer_id, DataStream dataStream) {

    Log.d( TAG, "onDataStream peer_id:" + peer_id + " label:" + dataStream.getLabel() );
    dataStream.setHandler( new DataStream.Handler() {
        @Override
        public void onOpen(DataStream myself) {
            Log.d( TAG, "DataStream.Handler.onOpen" );
        }

        @Override
        public void onMessage(DataStream dataStream, ByteBuffer message, boolean binary) {
            Log.d( TAG, "DataStream.Handler.onMessage length:" + message.capacity() );
            // Testing : Do an echo for text message
            if ( !binary ) {
                byte[] b = new byte[message.remaining()];
                message.get(b);

                dataStream.send( "(android echo) " +  new String(b));
            }
        }

        @Override
        public void onClose(DataStream myself) {
            Log.d( TAG, "DataStream.Handler.onClose" );
        }

        @Override
        public void onError(DataStream myself, String error) {
            Log.d( TAG, "DataStream.Handler.onError : " + error );
        }
    });
    }

    @Override
    public void onPresence(String peerId, Presence presence) {
        Log.v(TAG, "presence:"+presence);
    }

    @Override
    public void onIncomingRequest(String peerId, String peerName, String room, String event) {
        Log.v( TAG, "peerId:" + peerId + " peerName:" + peerName + " room:" + room + " event:" + event );
    }

    @Override
    public void onRoomMembers(String roomName, ArrayList<Member> members) {
        for (int i = 0; i < members.size(); i++) {
            Member member =  members.get(i);
            Log.v( TAG, "member id:" + member.id() + " name:" + member.name() );
        }
    }

    @Override
    public void onPeerJoinedRoom(String roomName, String peerId, String peerName) {
        Log.w( TAG, "A member has join the room " + roomName + " : " +peerName + " (" + peerId  + ")" );
    }

    @Override
    public void onPeerQuittedRoom(String roomName, String peerId) {
        Log.w( TAG, "A member has left the room " + roomName + " (" + peerId  + ")" );
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig)
    {
        super.onConfigurationChanged(newConfig);

        orientationLandscape = (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE);
        roomLayout.setOrientation(orientationLandscape ? LinearLayout.HORIZONTAL : LinearLayout.VERTICAL);
        callLayout.onOrientationChange(orientationLandscape);
    }

    @Override
    public void onRegister(Boolean success, String  value) {
        Log.w( TAG, "onRegister " + success + " : " +value );
    }

    @Override
    public void onUnregister(Boolean success, String  value) {
        Log.w( TAG, "onUnregister " + success + " : " +value );
    }

    @Override
    public void onRegistrationTokenFailed(String token) {
        Log.w( TAG, "onRegistrationTokenFailed " + token );
    }

    public void hideKeyboard() {
        InputMethodManager imm = (InputMethodManager)getSystemService(
                Context.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(roomEdit.getWindowToken(), 0);
    }

}
