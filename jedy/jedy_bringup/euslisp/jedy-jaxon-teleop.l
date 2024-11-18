#!/usr/bin/env roseus

(require "package://jedy_bringup/euslisp/jedy-interface.l")
;; (require "package://msl_hand_controller/euslisp/jaxon_red-interface.l")
(require "package://hrpsys_ros_bridge_tutorials/euslisp/jaxon_red-interface.l")

(ros::roseus "jaxon_jedy_teleop")

(defun jedy-teleop-init (&key
                   (namespace nil)
                   (controller-name "fullbody_controller"))
  (unless (boundp '*jedy*)
    (setq *jedy* (jedy)))
  (unless (boundp '*jedy-ri*)
    (setq *jedy-ri* (instance jedy-interface :init *jedy* :namespace namespace
                         :controller-name controller-name)))

  (ros::spin-once)
  (send *jedy-ri* :spin-once)
  (send *jedy* :angle-vector (send *jedy-ri* :state :potentio-vector)))

(defun jaxon_red-teleop-init (&rest args)
  (if (not (boundp '*jaxon_red-ri*))
      (setq *jaxon_red-ri* (instance* jaxon_red-interface :init args)))
  (if (not (boundp '*jaxon_red*))
      (setq *jaxon_red* (instance jaxon_red-robot :init))))

(jedy-teleop-init :namespace "jedymaster")
(jaxon_red-teleop-init)

(send *jedy* :translate #f(400 0 0))
(objects (list *jedy* *jaxon_red*))

(send *jedy-ri* :servo-off)

(defun sync-models ()
  (setq jedy-angle-vector (send *jedy-ri* :state :potentio-vector))
  (send *jedy* :angle-vector jedy-angle-vector)
  ;; (setq jaxon-angle-vector (send *jaxon_red-ri* :state :potentio-vector))
  ;; (send *jaxon_red* :angle-vector jaxon-angle-vector)
  (send *jaxon_red* :reset-pose)

  (send *jaxon_red* :rarm_joint1 :joint-angle (send *jedy* :rarm_joint0 :joint-angle))
  (send *jaxon_red* :rarm_joint2 :joint-angle (- (send *jedy* :rarm_joint1 :joint-angle) 20.0))
  (send *jaxon_red* :rarm_joint3 :joint-angle (send *jedy* :rarm_joint2 :joint-angle))
  (send *jaxon_red* :rarm_joint4 :joint-angle (send *jedy* :rarm_joint3 :joint-angle))
  (send *jaxon_red* :rarm_joint5 :joint-angle (+ (send *jedy* :rarm_joint4 :joint-angle) 90))
  (send *jaxon_red* :rarm_joint6 :joint-angle (send *jedy* :rarm_joint5 :joint-angle))
  (send *jaxon_red* :rarm_joint7 :joint-angle (- (send *jedy* :rarm_joint6 :joint-angle)))

  (send *jaxon_red* :larm_joint1 :joint-angle (- (send *jedy* :larm_joint0 :joint-angle)))
  (send *jaxon_red* :larm_joint2 :joint-angle (+ (send *jedy* :larm_joint1 :joint-angle) 20.0))
  (send *jaxon_red* :larm_joint3 :joint-angle (send *jedy* :larm_joint2 :joint-angle))
  (send *jaxon_red* :larm_joint4 :joint-angle (send *jedy* :larm_joint3 :joint-angle))
  (send *jaxon_red* :larm_joint5 :joint-angle (- (send *jedy* :larm_joint4 :joint-angle) 90))
  (send *jaxon_red* :larm_joint6 :joint-angle (- (send *jedy* :larm_joint5 :joint-angle)))
  (send *jaxon_red* :larm_joint7 :joint-angle (send *jedy* :larm_joint6 :joint-angle))
)

(print "initialize jedy to jaxon...")
(sync-models)
(send *jaxon_red-ri* :angle-vector (send *jaxon_red* :angle-vector) 10000)
(send *jaxon_red-ri* :wait-interpolation)
(print "initialize finished")

(ros::rate 5)

(do-until-key
  (sync-models)
  (send *jaxon_red-ri* :angle-vector (send *jaxon_red* :angle-vector) 180)
  (send *irtviewer* :draw-objects)
  (ros::sleep)
)
