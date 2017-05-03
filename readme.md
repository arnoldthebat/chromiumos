R57 Notes
xcb-proto 1.12-r2 needs to go into portage

May get collisions so remove:

sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES3/gl3platform.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES3/gl3.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES3/gl31.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/KHR/khrplatform.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/EGL/eglplatform.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/EGL/eglext.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/EGL/egl.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES2/gl2.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES2/gl2ext.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GLES2/gl2platform.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GL/glext.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GL/gl.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GL/glxext.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/include/GL/glx.h
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/lib64/libGL.so
sudo rm ~/chromiumos/chroot/build/amd64-atb/usr/lib64/libGL.so.1

Once building, sync changes from overlay to either portage-stable or chromiumos-overlay (not sure whats best yet)

Needs to be built with --nowithautotest since waffle is overridden
