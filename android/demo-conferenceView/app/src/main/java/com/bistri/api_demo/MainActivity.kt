package com.bistri.api_demo


import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Bundle
import android.text.InputFilter
import android.util.Log
import android.view.View
import android.view.animation.AnimationUtils
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.*
import android.widget.TextView.OnEditorActionListener
import com.bistri.api2.ConferenceHelper
import com.bistri.api2.ConferenceHelper.ConferenceHelperHandler
import com.bistri.api2.ConferenceView
import com.bistri.api2.wrapper.Conference.AudioOption
import com.bistri.api2.wrapper.Conference.VideoOption

class MainActivity : Activity(), View.OnClickListener, ConferenceHelperHandler {
    // Members
    private var room_edit: EditText? = null
    private var join_button: Button? = null
    private var mutevideo_button: Button? = null
    private var status: TextView? = null
    private var loader_spinner: ImageView? = null
    private var conferenceView: ConferenceView? = null
    private var room_layout: LinearLayout? = null
    private var permissions = false
    var conferenceHelper: ConferenceHelper? = null

    val TAG: String = MainActivity::class.java.getName()
    val DEFAULT_ROOM_NAME = "androidroom"
    val PERMISSIONS_CAMERA_AND_MICROPHONE = 1


    /*
    *       Activity Management
    */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.demo)
        room_edit = findViewById<View>(R.id.room_name) as EditText
        join_button = findViewById<View>(R.id.join_button) as Button
        mutevideo_button = findViewById<View>(R.id.mutevideo_button) as Button
        status = findViewById<View>(R.id.status) as TextView
        loader_spinner = findViewById<View>(R.id.loader_spinner) as ImageView
        conferenceView = findViewById<View>(R.id.confView) as ConferenceView
        conferenceView?.setVideoLayout(
            R.layout.my_member_view,
            R.id.name,
            R.id.description,
            R.id.picture
        )
        conferenceView?.setDefaultMemberPicture(R.drawable.member)
        conferenceView?.showLocalViewAsMiniature(true)
        conferenceView?.setBorders(4, -0xaaaaab)
        room_edit!!.setText(DEFAULT_ROOM_NAME)
        room_layout = findViewById<View>(R.id.room_layout) as LinearLayout
        val orientation_landscape =
            resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
        if (orientation_landscape) {
            room_layout!!.orientation = LinearLayout.HORIZONTAL
        } else {
            room_layout!!.orientation = LinearLayout.VERTICAL
        }

        // Force to use only Alphanumeric characters.
        val filter =
            InputFilter { source, start, end, dest, dstart, dend ->
                if (!source.toString().matches("[a-zA-Z0-9_-]*".toRegex() )) {
                    ""
                } else null
            }
        room_edit!!.filters = arrayOf(filter)

        // Set keyboard action
        room_edit!!.setOnEditorActionListener(OnEditorActionListener { v, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_SEND) {
                join_button!!.performClick()
                return@OnEditorActionListener true
            }
            false
        })

        // Set button listener
        join_button!!.setOnClickListener(this)
        mutevideo_button!!.setOnClickListener(this)
        initConference()
    }

    private fun checkPermission(): Boolean {
        permissions = conferenceHelper?.checkCameraAndMicrophonePermissions() == true
        if (!permissions) {
            // Missing permission
            androidx.core.app.ActivityCompat.requestPermissions(
                this,
                arrayOf<String>(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO),
                PERMISSIONS_CAMERA_AND_MICROPHONE
            )
        }
        return permissions
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>, grantResults: IntArray
    ) {
        if (requestCode == PERMISSIONS_CAMERA_AND_MICROPHONE) {
            if (grantResults.size > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initConference()
            } else {

                // permission denied
                Toast.makeText(this, R.string.permissions_error, Toast.LENGTH_LONG).show()
                finish()
            }
            return
        }
    }

    private fun initConference() {

        // Conference Helper
        conferenceHelper = ConferenceHelper.getInstance(applicationContext)
        conferenceHelper?.setConferenceView(conferenceView)
        conferenceHelper?.setHandler(this)
        if (!checkPermission()) {
            return
        }


        // Conference
        conferenceHelper?.getConference()?.apply {
            setInfo("38077edb", "4f304359baa6d0fd1f9106aaeb116f33", "Test User")
            setVideoOption(VideoOption.MAX_WIDTH, 640)
            setVideoOption(VideoOption.MAX_HEIGHT, 480)
            setVideoOption(VideoOption.MAX_FRAME_RATE, 30)
            setAudioOption(AudioOption.PREFERRED_CODEC_CLOCKRATE, 16000)
            setLoudspeaker(true)
            setLoudspeaker(true)
            volumeControlStream = AudioManager.STREAM_VOICE_CALL
            conferenceHelper!!.connect()
        }
    }

    fun showLoaderSpinner(visible: Boolean) {
        val visibility = if (visible) View.VISIBLE else View.GONE
        if (loader_spinner!!.visibility == visibility) return  // Nothing to do
        if (visible) {
            // Initialize loading spinner animation
            val rotation = AnimationUtils.loadAnimation(this, R.anim.rotate)
            if (rotation != null) loader_spinner!!.startAnimation(rotation)
        } else {
            loader_spinner!!.clearAnimation()
        }
        loader_spinner!!.visibility = visibility
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        conferenceHelper?.disconnect()
        super.onDestroy()
    }

    private fun updateViewAccordingState(isConnected: Boolean, statusStr: String) {
        // status.setText( statusStr );
        showLoaderSpinner(statusStr == "CONNECTING")
        room_edit!!.isEnabled = isConnected
        join_button!!.isEnabled = isConnected
    }

    private fun setInCall(inCall: Boolean) {
        room_layout!!.visibility = if (inCall) View.GONE else View.VISIBLE
        conferenceView?.setVisibility(if (inCall) View.VISIBLE else View.GONE)
        mutevideo_button!!.visibility = if (inCall) View.VISIBLE else View.GONE
        if (inCall) {
            hideKeyboard()
        } else {
            conferenceView?.removeAll()
        }
    }

    override fun onBackPressed() {
        Log.w(TAG, "onBackPressed")
        if (conferenceHelper?.isInRoom() == true) {
            conferenceHelper?.leaveRoom()
            return
        }
        super.onBackPressed()
    }

    override fun onClick(view: View) {
        Log.d(TAG, "onClick")
        when (view.id) {
            R.id.join_button -> {
                val room_name = room_edit!!.text.toString()
                if (room_name.length == 0) {
                    Toast.makeText(this, R.string.create_input_error, Toast.LENGTH_SHORT).show()
                    return
                }
                if (conferenceHelper?.isConnected() == true) {
                    conferenceHelper?.joinRoom(room_name)
                    Log.d(TAG, "Join room $room_name")
                    return
                }
                Log.w(TAG, "Cannot join room : not connected")
            }
            R.id.mutevideo_button -> {
                val label = mutevideo_button!!.text.toString()
                if (label.compareTo("unmute video") == 0) {
                    mutevideo_button!!.text = "mute video"
                    conferenceView?.unmuteVideo("local")
                } else {
                    mutevideo_button!!.text = "unmute video"
                    conferenceView?.muteVideo("local")
                }
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        val orientation_landscape = newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE
        room_layout!!.orientation =
            if (orientation_landscape) LinearLayout.HORIZONTAL else LinearLayout.VERTICAL
    }

    fun hideKeyboard() {
        val imm = getSystemService(
            INPUT_METHOD_SERVICE
        ) as InputMethodManager
        imm.hideSoftInputFromWindow(room_edit!!.windowToken, 0)
    }

    override fun onConferenceEvent(eventName: String, value: String?) {
        /*
            Possible values :
            DISCONNECTED (no args)
            CONNECTING (no args)
            CONNECTED (no args)
            ERROR kind
            ROOM_JOINED room
            ROOM_QUITTED room
            ON_MEMBERS
            MEMBER_JOINED_ROOM memberID
            MEMBER_LEFT_ROOM memberID
         */
        Log.i(TAG, eventName + ":" + (value ?: ""))
        updateViewAccordingState(conferenceHelper?.isConnected() == true, eventName)
        if (eventName == "ROOM_QUITTED") {
            setInCall(false)
        } else if (eventName == "ROOM_JOINED") {
            setInCall(true)
        }
    }

}
