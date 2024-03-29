function R_body_ned = tool_R_body_ned(q0,q1,q2,q3)
%R_BODY_NED
%    R_BODY_NED = R_BODY_NED(Q0,Q1,Q2,Q3)

%    This function was generated by the Symbolic Math Toolbox version 6.0.
%    23-Jan-2015 15:51:05

t2 = q0.*q3.*2.0;
t3 = q1.*q2.*2.0;
t4 = q0.^2;
t5 = q1.^2;
t6 = q2.^2;
t7 = q3.^2;
t8 = q1.*q3.*2.0;
t9 = q0.*q1.*2.0;
t10 = q2.*q3.*2.0;
R_body_ned = reshape([t4+t5-t6-t7,-t2+t3,t8+q0.*q2.*2.0,t2+t3,t4-t5+t6-t7,-t9+t10,t8-q0.*q2.*2.0,t9+t10,t4-t5-t6+t7],[3, 3]);
